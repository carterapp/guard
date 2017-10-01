defmodule Doorman.User do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Poison.Encoder, only: [:id, :username, :fullname, :email, :requested_email, :attrs, :inserted_at, :updated_at]}

  schema "users" do
    field :username, :string
    field :fullname, :string
    field :locale, :string
    field :email, :string
    field :password, :string, virtual: true
    field :enc_password, :string
    field :perms, :map
    field :requested_email, :string
    field :provider, :map
    field :confirmation_token, :string
    field :attrs, :map
    field :pin, :string
    field :pin_timestamp, :utc_datetime

    timestamps()
  end

  @required_fields ~w(username)a
  @optional_fields ~w(password email enc_password perms requested_email provider fullname locale attrs pin pin_timestamp)a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:requested_email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_length(:username, min: 1)
    |> validate_confirmation(:password, message: "password_mismatch")
    |> update_change(:email, &String.downcase/1) #Lowercase email, so we can check for duplicates
    |> update_change(:requested_email, &String.downcase/1) #Lowercase email, so we can check for duplicates
    |> update_change(:username, &String.downcase/1) #Lowercase username, so we can check for duplicates
    |> unique_constraint(:email, message: "email_taken")
    |> unique_constraint(:requested_email, message: "email_requested")
    |> unique_constraint(:username, message: "username_taken")
    |> encrypt_changeset()
  end

  def encrypt_password(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.checkpw(password, user.enc_password)
  end
  
  def check_pin(user, pin) do
    pin_valid_time = 60 * 60 #Pin valid for one hour
    user.pin != nil 
      && user.pin_timestamp != nil 
      && DateTime.diff(DateTime.utc_now(), user.pin_timestamp) < pin_valid_time 
      && pin == user.pin
  end


  defp encrypt_changeset(current_changeset) do
     case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(current_changeset, :enc_password, encrypt_password(password))
      _ ->
        current_changeset
    end
  end
end
