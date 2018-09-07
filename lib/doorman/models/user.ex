defmodule Doorman.User do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Poison.Encoder, only: [:id, :username, :fullname, :email, :requested_email, :attrs, :inserted_at, :updated_at, :mobile, :requested_mobile]}

  schema "users" do
    field :username, :string
    field :fullname, :string
    field :locale, :string
    field :email, :string
    field :mobile, :string
    field :requested_mobile, :string
    field :password, :string, virtual: true
    field :enc_password, :string
    field :perms, :map
    field :requested_email, :string
    field :provider, :map
    field :confirmation_token, :string
    field :attrs, :map
    field :pin, :string, virtual: true
    field :enc_pin, :string
    field :pin_expiration, :utc_datetime

    timestamps()
  end

  @required_fields ~w(username)a
  @optional_fields ~w(password email enc_password perms requested_email provider confirmation_token fullname locale attrs pin enc_pin pin_expiration mobile requested_mobile)a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:requested_email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_length(:username, min: 1)
    |> validate_confirmation(:password, message: "password_mismatch")
    |> update_change(:email, &downcase/1) #Lowercase email, so we can check for duplicates
    |> update_change(:requested_email, &downcase/1) #Lowercase email, so we can check for duplicates
    |> update_change(:username, &downcase/1) #Lowercase username, so we can check for duplicates
    |> unique_constraint(:email, message: "email_taken")
    |> unique_constraint(:mobile, message: "mobile_taken")
    |> unique_constraint(:username, message: "username_taken")
    |> encrypt_password()
    |> encrypt_pin()
  end

  defp downcase(v) do
    if v != nil do
      v |> String.trim() |> String.downcase()
    else
      v
    end
  end

  def hash_password(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.checkpw(password, user.enc_password)
  end

  def check_pin(user, pin) do
    user.enc_pin != nil
      && user.pin_expiration != nil
      && DateTime.diff(DateTime.utc_now(), user.pin_expiration) < 0
      && Comeonin.Bcrypt.checkpw(pin, user.enc_pin)
  end

  defp encrypt_password(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(current_changeset, :enc_password, hash_password(password))
      _ ->
        current_changeset
    end
  end

  defp encrypt_pin(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{pin: pin}} ->
        put_change(current_changeset, :enc_pin, hash_password(pin))
      _ ->
        current_changeset
    end
  end

end
