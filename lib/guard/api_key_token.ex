defmodule Guard.ApiKeyToken do
  @behaviour Guardian.Token

  alias Guard.{Users, UserApiKey, ApiKey}

  @type_key "typ"
  @default_token_type "access"

  def peek(_mod, nil), do: nil

  def peek(mod, token) do
    case Users.get_api_by_key(token) do
      nil ->
        nil

      api_key ->
        {:ok, sub, claims} = create_claims(api_key)
        {:ok, claims} = build_claims(mod, nil, sub, claims, [])
        %{claims: claims}
    end
  end

  def token_id, do: Guardian.UUID.generate()

  def create_token(_mod, claims, _opts) do
    {:ok, claims}
  end

  def build_claims(mod, _resource, sub, claims, options) do
    claims =
      claims
      |> Guardian.stringify_keys()
      |> Map.put("sub", sub)
      |> set_type(mod, options)

    {:ok, claims}
  end

  defp create_claims(%UserApiKey{} = key) do
    {:ok, sub} = ApiKey.subject_for_token(key, nil)
    claims = Guard.ApiKey.encode_permissions_into_claims!(%{}, key.permissions || %{})
    {:ok, sub, claims}
  end

  def decode_token(mod, token, opts) do
    case Users.get_api_by_key(token) do
      nil ->
        {:error, :api_key_not_found}

      key ->
        {:ok, sub, claims} = create_claims(key)
        build_claims(mod, nil, sub, claims, opts)
    end
  end

  defp set_type(%{"typ" => typ} = claims, _mod, _opts) when not is_nil(typ), do: claims

  defp set_type(claims, mod, opts) do
    defaults = apply(mod, :default_token_type, [])
    typ = Keyword.get(opts, :token_type, defaults)
    Map.put_new(claims, @type_key, to_string(typ || @default_token_type))
  end

  def verify_claims(_mod, claims, _opts) do
    {:ok, claims}
  end

  def revoke(_mod, claims, token, _opts) do
    case Users.get_api_by_key(token) do
      nil -> nil
      key -> Users.delete_api_key(key)
    end

    {:ok, claims}
  end

  def refresh(_mod, _old_token, _opts) do
    {:error, :not_refreshable}
  end

  def exchange(_mod, _old_token, _from_type, _to_type, _opts) do
    {:error, :not_exchangeable}
  end
end
