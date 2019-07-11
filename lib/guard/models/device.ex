defmodule Guard.Device do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Jason.Encoder,
           only: [
             :id,
             :token,
             :platform,
             :user_id,
             :last_sent,
             :inserted_at,
             :updated_at,
             :registered_at
           ]}

  schema "devices" do
    field(:token, :string)
    field(:platform, :string)
    field(:user_id, :binary_id)
    field(:last_sent, :utc_datetime)
    field(:registered_at, :utc_datetime)

    timestamps()
  end

  @required_fields ~w(token platform)a
  @optional_fields ~w(user_id last_sent registered_at)a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
