defmodule Guard.User do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Jason.Encoder,
           only: [
             :id,
             :username,
             :fullname,
             :email,
             :requested_email,
             :attrs,
             :inserted_at,
             :updated_at,
             :mobile,
             :requested_mobile
           ]}

  schema "users" do
    field(:username, :string)
    field(:fullname, :string)
    field(:locale, :string)
    field(:email, :string)
    field(:requested_email, :string)
    field(:mobile, :string)
    field(:requested_mobile, :string)
    field(:password, :string, virtual: true)
    field(:enc_password, :string)
    field(:perms, :map)
    field(:provider, :map)
    field(:attrs, :map)
    field(:pin, :string, virtual: true)
    field(:enc_pin, :string)
    field(:pin_expiration, :utc_datetime)
    field(:email_pin, :string, virtual: true)
    field(:enc_email_pin, :string)
    field(:email_pin_expiration, :utc_datetime)

    field(:context, :map, virtual: true, default: %{})

    timestamps()
  end

  @required_fields ~w(username)a
  @optional_fields ~w(password email enc_password perms requested_email provider fullname locale attrs pin enc_pin pin_expiration
                      email_pin enc_email_pin email_pin_expiration mobile requested_mobile context)a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:requested_email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_length(:username, min: 1)
    |> validate_confirmation(:password, message: "password_mismatch")
    # Lowercase email, so we can check for duplicates
    |> update_change(:email, &downcase/1)
    # Lowercase email, so we can check for duplicates
    |> update_change(:requested_email, &downcase/1)
    # Lowercase username, so we can check for duplicates
    |> update_change(:username, &downcase/1)
    # Remove all spaces and leading + from mobile phone
    |> update_change(:mobile, &clean_mobile_number/1)
    # Remove all spaces and leading + from mobile phone
    |> update_change(:requested_mobile, &clean_mobile_number/1)
    |> unique_constraint(:email, message: "email_taken")
    |> unique_constraint(:mobile, message: "mobile_taken")
    |> unique_constraint(:username, message: "username_taken")
    |> encrypt_password()
    |> encrypt_pin()
    |> encrypt_email_pin()
    |> validate_password()
  end

  def clean_mobile_number(v) do
    if v do
      v |> String.replace("+", "") |> String.replace(" ", "")
    else
      v
    end
  end

  def downcase(v) do
    if v != nil do
      v |> String.trim() |> String.downcase()
    else
      v
    end
  end

  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  def check_password(user, password) do
    Bcrypt.verify_pass(password, user.enc_password)
  end

  defp validate_password(changeset) do
    if get_field(changeset, :enc_password, nil) do
      changeset
    else
      if get_field(changeset, :password, nil) do
        changeset
      else
        add_error(changeset, :password, "cannot be empty")
      end
    end
  end

  defp validate_pin(user_pin, exp_time, check_pin) do
    cond do
      !user_pin -> {:error, :no_pin}
      exp_time && DateTime.diff(DateTime.utc_now(), exp_time) > 0 -> {:error, :pin_expired}
      Bcrypt.verify_pass(check_pin, user_pin) -> :ok
      true -> {:error, :wrong_pin}
    end
  end

  def validate_email_pin(user, pin) do
    validate_pin(user.enc_email_pin, user.email_pin_expiration, pin)
  end

  def validate_pin(user, pin) do
    validate_pin(user.enc_pin, user.pin_expiration, pin)
  end

  def check_pin(user, pin) do
    case validate_pin(user, pin) do
      :ok -> true
      _ -> false
    end
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

  defp encrypt_email_pin(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{email_pin: pin}} ->
        put_change(current_changeset, :enc_email_pin, hash_password(pin))

      _ ->
        current_changeset
    end
  end
end
