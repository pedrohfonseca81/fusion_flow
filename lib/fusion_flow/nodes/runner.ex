defmodule FusionFlow.Nodes.Runner do
  alias FusionFlow.Nodes.Registry

  def run(flow) do
    start_node =
      Enum.find(flow.nodes, fn node -> node["type"] == "Start" || node["label"] == "Start" end)

    if start_node do
      initial_context = %{
        "flow_id" => flow.id,
        "logs" => []
      }

      case execute_node(start_node, initial_context, flow) do
        {:ok, execution_result} -> {:ok, execution_result}
        {:error, reason, node_id} -> {:error, reason, node_id}
      end
    else
      {:error, "No Start node found", nil}
    end
  end

  defp execute_node(node, context, flow) do
    node_type = node["type"] || node["label"]
    definition = Registry.get_node(node_type)

    if definition do
      module = get_node_module(node_type)

      context = if is_map(context), do: context, else: %{"result" => context}
      node_context = Map.merge(context, node["controls"] || %{})

      try do
        case apply(module, :handler, [node_context, nil]) do
          {:ok, result, output_name} ->
            connections =
              flow.connections
              |> Enum.filter(fn c ->
                c["source"] == node["id"] && c["sourceOutput"] == to_string(output_name)
              end)

            process_connections(connections, result, flow)

          {:ok, result} ->
            output_name = List.first(definition[:outputs]) || "exec"

            connections =
              flow.connections
              |> Enum.filter(fn c ->
                c["source"] == node["id"] && c["sourceOutput"] == to_string(output_name)
              end)

            process_connections(connections, result, flow)

          {:result, value} ->
            output_name = List.first(definition[:outputs]) || "exec"
            new_context = Map.put(context, "result", value)

            connections =
              flow.connections
              |> Enum.filter(fn c ->
                c["source"] == node["id"] && c["sourceOutput"] == to_string(output_name)
              end)

            process_connections(connections, new_context, flow)

          {:error, reason} ->
            if "error" in (definition[:outputs] || []) do
              connections =
                flow.connections
                |> Enum.filter(fn c ->
                  c["source"] == node["id"] && c["sourceOutput"] == "error"
                end)

              process_connections(connections, reason, flow)
            else
              {:error, reason, to_string(node["id"])}
            end
        end
      rescue
        e ->
          {:error, Exception.message(e), to_string(node["id"])}
      catch
        kind, reason ->
          formatted_reason = Exception.format(kind, reason, __STACKTRACE__)
          {:error, formatted_reason, to_string(node["id"])}
      end
    else
      {:ok, context}
    end
  end

  defp process_connections(connections, context, flow) do
    Enum.reduce_while(connections, {:ok, context}, fn conn, {:ok, acc_context} ->
      target_node = Enum.find(flow.nodes, fn n -> n["id"] == conn["target"] end)

      if target_node do
        case execute_node(target_node, acc_context, flow) do
          {:ok, next_ctx} -> {:cont, {:ok, next_ctx}}
          {:error, r, n} -> {:halt, {:error, r, n}}
        end
      else
        {:cont, {:ok, acc_context}}
      end
    end)
  end

  defp get_node_module("Start"), do: FusionFlow.Nodes.Start
  defp get_node_module("Variable"), do: FusionFlow.Nodes.Variable
  defp get_node_module("Output"), do: FusionFlow.Nodes.Output
  defp get_node_module("Evaluate Code"), do: FusionFlow.Nodes.Eval
  defp get_node_module("HTTP Request"), do: FusionFlow.Nodes.HttpRequest

  defp get_node_module(name) do
    module_name = "Elixir.FusionFlow.Nodes.#{String.replace(name, " ", "")}"

    try do
      String.to_existing_atom(module_name)
    rescue
      _ -> nil
    end
  end
end
