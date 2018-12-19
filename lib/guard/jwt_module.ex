defmodule Guard.Jwt do
    use Guardian, otp_app: :guard,
      permissions: Application.get_env(:guard, Guard.Guardian)[:permissions] 

  use Guardian.Permissions.Bitwise

  alias Guard.{Repo, User}


  def subject_for_token(%User{} = user, _claims) do
    {:ok, "User:#{user.id}"}
  end

  def subject_for_token(_, _), do: {:error, :unknown_resource}

  def load_resource("User:" <> id), do: Repo.get!(User, id)

  def load_resource(_), do: nil

  def resource_from_claims(%{"sub" => sub} = _claims) do
    {:ok, load_resource(sub)}
  end

  def resource_from_claims(_claims), do: {:error, :unknown_resource}

  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> encode_permissions_into_claims!(Keyword.get(opts, :perms))
    {:ok, claims}
  end


end
