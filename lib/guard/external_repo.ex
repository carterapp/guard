defmodule Guard.ExternalRepo do

  defmacro __using__(_opts) do
    repo = Application.get_env(:guard, Guard.ExternalRepo)[:repo]
    if repo do
      quote do
        Process.register(GenServer.whereis(repo), Guard.Repo)
      end

      # automatically generate delegate for all functions in repo, which 
      # look like something like this:
      #     ...
      #     defdelegate update_all(a,b,c), to: unquote(repo)
      #     ...
      repo.__info__(:functions)
      |> Enum.map(fn({function, arity}) ->
        case arity do
          0 -> quote do defdelegate unquote(function)(), to: unquote(repo) end
          1 -> quote do defdelegate unquote(function)(a), to: unquote(repo) end
          2 -> quote do defdelegate unquote(function)(a,b), to: unquote(repo) end
          3 -> quote do defdelegate unquote(function)(a,b,c), to: unquote(repo) end
          4 -> quote do defdelegate unquote(function)(a,b,c,d), to: unquote(repo) end
          _ -> raise "Unexpected arity for function in Repo"
        end
      end)
    end
  end
end
