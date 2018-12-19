defmodule Guard.ApiKey do
    use Guardian, otp_app: :guard,
      token_module: Guard.ApiKeyToken,
      permissions: Application.get_env(:guard, Guard.Guardian)[:permissions] 

  use Guardian.Permissions.Bitwise

  alias Guard.{Repo, UserApiKey}

  def subject_for_token(%UserApiKey{} = key, _claims) do
    {:ok, "key:#{key.id}"}
  end

  def subject_for_token(_, _), do: {:error, :unknown_resource}

  def load_resource("key:" <> id), do: Repo.get!(UserApiKey, id)

  def load_resource(_), do: nil

  def resource_from_claims(%{"sub" => sub} = _claims) do
    {:ok, load_resource(sub)}
  end

  def resource_from_claims(_claims), do: {:error, :unknown_resource}

  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
    {:ok, claims}
  end


end
