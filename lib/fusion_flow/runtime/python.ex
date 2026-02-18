defmodule FusionFlow.Runtime.Python do
  @behaviour FusionFlow.Runtime.Executor
  require Logger

  def execute(code, context) do
    try do
      {result, _globals} = Pythonx.eval(code, context)

      final_result =
        cond do
          is_nil(result) ->
            nil

          is_struct(result, Pythonx.Object) ->
            decoded = Pythonx.decode(result)
            decoded

          true ->
            result
        end

      case final_result do
        %{} = new_ctx -> {:ok, new_ctx}
        other -> {:result, other}
      end
    rescue
      e ->
        Logger.error("Python Execution Error: #{inspect(e)}")
        {:error, Exception.message(e)}
    catch
      kind, reason ->
        {:error, Exception.format(kind, reason, __STACKTRACE__)}
    end
  end
end
