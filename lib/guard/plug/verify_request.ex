if Code.ensure_loaded?(Plug) do
  defmodule Guard.Plug.VerifyRequest do
    @moduledoc """
    Looks for and validates a token found in request parameter.

    * `:key` - The location of the token (default `:default`)
    * `:parameter` - The name of the request parameter. Default `"_t"`
    """

    import Plug.Conn
    import Guardian.Plug.Keys

    alias Guardian.Plug.Pipeline

    @behaviour Plug

    @impl Plug
    @spec init(opts :: Keyword.t()) :: Keyword.t()
    def init(opts), do: opts

    @impl Plug
    @spec call(conn :: Plug.Conn.t(), opts :: Keyword.t()) :: Plug.Conn.t()
    def call(conn, opts) do
      with nil <- Guardian.Plug.current_token(conn, opts),
           {:ok, token} <- fetch_token_from_request(conn, opts),
           module <- Pipeline.fetch_module!(conn, opts),
           claims_to_check <- Keyword.get(opts, :claims, %{}),
           key <- storage_key(conn, opts),
           {:ok, claims} <- Guardian.decode_and_verify(module, token, claims_to_check, opts) do

        conn
        |> Guardian.Plug.put_current_token(token, key: key)
        |> Guardian.Plug.put_current_claims(claims, key: key)
      else
        :no_token_found ->
          conn

        # Let the ensure_authenticated plug handle the token expired later in the pipeline
        {:error, :token_expired} ->
          conn

        {:error, reason} ->
          conn
          |> Pipeline.fetch_error_handler!(opts)
          |> apply(:auth_error, [conn, {:invalid_token, reason}, opts])
          |> halt()

        _ ->
          conn
      end
    end

    defp fetch_token_from_request(conn, opts) do
      param = Keyword.get(opts, :parameter, "_t")
      token = conn.params[param]
      if token, do: {:ok, token}, else: :no_token_found
    end

    defp maybe_put_in_session(conn, false, _, _), do: conn

    defp maybe_put_in_session(conn, true, token, opts) do
      key = conn |> storage_key(opts) |> token_key()
      put_session(conn, key, token)
    end

    defp storage_key(conn, opts), do: Pipeline.fetch_key(conn, opts)
  end
end
