defmodule FusionFlow.Runtime.Elixir do
  @behaviour FusionFlow.Runtime.Executor

  def execute(code, context) do
    Process.put(:fusion_flow_eval_context, context)

    code_with_imports = "import FusionFlow.Nodes.Eval; " <> (code || "")

    {result, diagnostics} =
      Code.with_diagnostics(fn ->
        try do
          last_result = context["result"]
          bindings = [input: context["input"], context: context, result: last_result]

          {binding, _} = Code.eval_string(code_with_imports, bindings)
          {:ok, binding}
        rescue
          e -> {:error, e}
        catch
          kind, reason -> {:error, {kind, reason, __STACKTRACE__}}
        end
      end)

    Process.delete(:fusion_flow_eval_context)

    case result do
      {:ok, binding} ->
        case binding do
          {:ok, %{} = new_context} ->
            {:ok, new_context}

          %{} = new_context ->
            {:ok, new_context}

          {:ok, value} ->
            {:result, value}

          other_value ->
            {:result, other_value}
        end

      {:error, exception_or_reason} ->
        error_message =
          if diagnostics != [] do
            format_diagnostics(diagnostics)
          else
            case exception_or_reason do
              {kind, reason, stack} -> Exception.format(kind, reason, stack)
              e -> Exception.message(e)
            end
          end

        {:error, error_message}
    end
  end

  defp format_diagnostics(diagnostics) do
    diagnostics
    |> Enum.map(fn diag ->
      "Error on line #{diag.position}: #{diag.message}"
    end)
    |> Enum.join("\n")
  end
end
