defmodule Guard.UserApiKey do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Jason.Encoder, only: [:id, :key, :user_id, :name, :permissions, :inserted_at, :updated_at]}
  @derive {Poison.Encoder, only: [:id, :key, :user_id, :name, :permissions, :inserted_at, :updated_at]}

  schema "user_api_keys" do
    field :key, :string
    field :user_id, :binary_id
    field :name, :string
    field :permissions, :map, default: %{}

    timestamps()
  end

  @required_fields ~w(key user_id)a
  @optional_fields ~w(key user_id permissions name)a

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
