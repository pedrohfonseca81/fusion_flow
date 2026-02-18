defmodule FusionFlow.Nodes.Eval do
  @moduledoc """
  Evaluate Code node definition.
  """

  def definition do
    %{
      name: "Evaluate Code",
      category: :code,
      icon: "</>",
      inputs: [:exec],
      outputs: [:exec],
      ui_fields: [
        %{
          type: :select,
          name: :language,
          label: "Language",
          options: ["elixir", "python"],
          default: "elixir"
        },
        %{
          type: :code,
          name: :code,
          label: "Code Editor",
          render: "button",
          language_field: :language,
          default: ""
        }
      ]
    }
  end

  def variable(name) do
    context = Process.get(:fusion_flow_eval_context, %{})
    key = to_string(name)
    Map.get(context, key)
  end

  def variable!(name) do
    context = Process.get(:fusion_flow_eval_context, %{})
    key = to_string(name)

    case Map.fetch(context, key) do
      {:ok, val} -> val
      :error -> raise "Variable '#{key}' not found in context"
    end
  end

  def handler(context, input) do
    Process.put(:fusion_flow_eval_context, context)

    # Use the selected language or default to elixir for backward compatibility
    language = context["language"] || "elixir"

    # Select the appropriate code field based on language
    # Fallback to legacy "code" field for backward compatibility
    code =
      case language do
        "elixir" -> context["code_elixir"] || context["code"] || ""
        "python" -> context["code_python"] || ""
        _ -> ""
      end

    # Inject input into context for the executor if not already there
    context = Map.put(context, "input", input)

    result =
      case language do
        "elixir" -> FusionFlow.Runtime.Elixir.execute(code, context)
        "python" -> FusionFlow.Runtime.Python.execute(code, context)
        _ -> {:error, "Unsupported language: #{language}"}
      end

    Process.delete(:fusion_flow_eval_context)
    result
  end
end
