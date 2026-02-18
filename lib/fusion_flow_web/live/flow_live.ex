defmodule FusionFlowWeb.FlowLive do
  use FusionFlowWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    flow = FusionFlow.Flows.get_flow!(id)

    {:ok,
     socket
     |> assign(
       has_changes: false,
       modal_open: false,
       dependencies_modal_open: false,
       dependencies_tab: "elixir",
       search_query: "",
       search_results: [],
       installed_deps: [],
       terminal_logs: [],
       pending_restart_deps: [],
       installing_dep: nil,
       current_node_id: nil,
       current_code_elixir: "",
       current_code_python: "",
       current_code_tab: "elixir",
       current_field_name: nil,
       current_language: "elixir",
       config_modal_open: false,
       editing_node_data: nil,
       nodes_by_category: FusionFlow.Nodes.Registry.nodes_by_category(),
       current_flow: flow,
       current_flow: flow,
       execution_result: nil,
       show_result_modal: false,
       error_modal_open: false,
       current_error_message: nil,
       current_error_message: nil,
       current_error_node_id: nil,
       current_error_node_id: nil,
       available_variables: [],
       chat_open: false,
       chat_messages: [],
       pending_ai_trigger: false,
       chat_loading: false,
       ai_configured: System.get_env("OPENAI_API_KEY") not in [nil, ""]
     )}
  end

  @impl true
  def handle_event("client_ready", _params, socket) do
    flow = socket.assigns.current_flow
    nodes = flow.nodes || []
    connections = flow.connections || []

    unique_node_types =
      nodes
      |> Enum.map(fn node -> node["type"] || node["label"] end)
      |> Enum.uniq()

    definitions =
      Enum.reduce(unique_node_types, %{}, fn type, acc ->
        Map.put(acc, type, FusionFlow.Nodes.Registry.get_node(type))
      end)

    {:noreply,
     push_event(socket, "load_graph_data", %{
       nodes: nodes,
       connections: connections,
       definitions: definitions
     })}
  end

  @impl true
  def handle_event("add_node", %{"name" => name} = _params, socket) do
    definition = FusionFlow.Nodes.Registry.get_node(name)
    {:noreply, push_event(socket, "add_node", %{name: name, definition: definition})}
  end

  @impl true
  def handle_event("run_flow", _params, socket) do
    {:noreply, push_event(socket, "request_save_and_run", %{})}
  end

  @impl true
  def handle_event("save_and_run", %{"data" => data}, socket) do
    case FusionFlow.Flows.update_flow(socket.assigns.current_flow, data) do
      {:ok, updated_flow} ->
        case FusionFlow.Nodes.Runner.run(updated_flow) do
          {:ok, result_context} ->
            {:noreply,
             socket
             |> assign(current_flow: updated_flow, has_changes: false)
             |> put_flash(:info, "Flow saved and executed successfully!")
             |> push_event("clear_node_errors", %{})
             |> assign(execution_result: result_context, show_result_modal: true)}

          {:error, reason, node_id} ->
            error_msg = if is_binary(reason), do: reason, else: inspect(reason)

            socket =
              socket
              |> assign(current_flow: updated_flow, has_changes: false)
              |> put_flash(:error, "Flow saved, but execution failed: #{error_msg}")

            socket =
              if node_id do
                push_event(socket, "highlight_node_error", %{
                  nodeId: to_string(node_id),
                  message: error_msg
                })
              else
                socket
              end

            {:noreply, socket}
        end

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save flow before running.")}
    end
  end

  @impl true
  def handle_event("graph_changed", _params, socket) do
    {:noreply, assign(socket, has_changes: true)}
  end

  @impl true
  def handle_event(
        "open_code_editor",
        %{"nodeId" => node_id, "fieldName" => field_name, "language" => language} =
          params,
        socket
      ) do
    variables = params["variables"] || []

    # Load both code_elixir and code_python from params if available
    code_elixir = params["code_elixir"] || params["code"] || ""
    code_python = params["code_python"] || ""

    {:noreply,
     assign(socket,
       modal_open: true,
       current_node_id: node_id,
       current_code_elixir: code_elixir,
       current_code_python: code_python,
       current_code_tab: language,
       current_field_name: field_name,
       current_language: language,
       available_variables: variables
     )}
  end

  @impl true
  def handle_event("toggle_chat", _params, socket) do
    {:noreply, assign(socket, chat_open: !socket.assigns.chat_open)}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    IO.inspect(content, label: "RECEIVED MESSAGE CONTENT")

    if content == "" do
      {:noreply, socket}
    else
      messages = socket.assigns.chat_messages ++ [{:user, content}]
      messages = messages ++ [{:ai, ""}]

      ai_messages =
        Enum.map(messages, fn
          {:user, text} -> %{role: "user", content: text}
          {:ai, text} -> %{role: "assistant", content: text}
        end)

      ai_messages = List.delete_at(ai_messages, -1)

      socket = assign(socket, chat_messages: messages, chat_loading: true)

      parent = self()

      socket =
        start_async(socket, :ai_stream, fn ->
          current_flow = socket.assigns.current_flow

          case FusionFlow.Agents.FlowCreator.chat(ai_messages, current_flow) do
            {:ok, result} ->
              Enum.reduce_while(result.stream, :ok, fn event, _acc ->
                case event do
                  {:text_delta, text} ->
                    send(parent, {:chat_stream_chunk, text})
                    {:cont, :ok}

                  {:error, reason} ->
                    send(parent, {:chat_stream_error, reason})
                    {:halt, {:error, reason}}

                  {:finish, _reason} ->
                    {:cont, :ok}

                  _ ->
                    {:cont, :ok}
                end
              end)

              IO.puts("ASYNC TASK: Stream loop finished")
              :ok

            error ->
              IO.inspect(error, label: "ASYNC TASK: AI Stream Error")
              error
          end
        end)

      {:noreply, socket}
    end
  end

  def handle_info({:chat_stream_chunk, chunk}, socket) do
    messages = socket.assigns.chat_messages
    {last_role, last_content} = List.last(messages)

    updated_messages =
      if last_role == :ai do
        List.replace_at(messages, -1, {:ai, last_content <> chunk})
      else
        messages
      end

    {:noreply, assign(socket, chat_messages: updated_messages)}
  end

  def handle_async(:ai_stream, {:ok, _result}, socket) do
    messages = socket.assigns.chat_messages
    {role, content} = List.last(messages)

    socket =
      if role == :ai do
        json_content =
          content
          |> String.replace(~r/^```json\s*/, "")
          |> String.replace(~r/\s*```$/, "")
          |> String.trim()

        case Jason.decode(json_content) do
          {:ok, %{"action" => "create_flow", "nodes" => raw_nodes, "connections" => connections}} ->
            nodes =
              Enum.map(raw_nodes, fn node ->
                data = node["data"] || %{}

                label = node["label"] || data["label"] || node["name"]

                position =
                  node["position"] ||
                    %{"x" => data["x"] || 0, "y" => data["y"] || 0}

                controls =
                  cond do
                    is_map(node["controls"]) and node["controls"] != %{} ->
                      node["controls"]

                    is_map(data["controls"]) and data["controls"] != %{} ->
                      data["controls"]

                    true ->
                      Map.drop(data, ["label", "x", "y", "controls"])
                  end

                controls =
                  Enum.into(controls, %{}, fn {k, v} ->
                    if is_map(v) and Map.has_key?(v, "value") do
                      {k, v["value"]}
                    else
                      {k, v}
                    end
                  end)

                %{
                  "id" => node["id"],
                  "name" => node["name"],
                  "type" => node["type"] || node["name"],
                  "label" => label,
                  "position" => position,
                  "controls" => controls,
                  "inputs" => node["inputs"] || %{},
                  "outputs" => node["outputs"] || %{}
                }
              end)
              |> Enum.with_index()
              |> Enum.map(fn {node, index} ->
                current_y = get_in(node, ["position", "y"]) || 100
                new_x = 100 + index * 500

                Map.put(node, "position", %{"x" => new_x, "y" => current_y})
              end)

            unique_node_types =
              nodes
              |> Enum.map(fn node -> node["type"] end)
              |> Enum.uniq()

            definitions =
              Enum.reduce(unique_node_types, %{}, fn type, acc ->
                Map.put(acc, type, FusionFlow.Nodes.Registry.get_node(type))
              end)

            socket
            |> push_event("load_graph_data", %{
              nodes: nodes,
              connections: connections,
              definitions: definitions
            })
            |> put_flash(:info, "Flow generated by AI applied successfully!")
            |> assign(has_changes: true)
            |> update(:chat_messages, fn messages ->
              List.replace_at(
                messages,
                -1,
                {:ai, "Flow created successfully! You can see it on the canvas."}
              )
            end)

          _ ->
            socket
        end
      else
        socket
      end

    {:noreply, assign(socket, chat_loading: false)}
  end

  def handle_async(:ai_stream, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "AI Stream failed: #{inspect(reason)}")
     |> assign(chat_loading: false)}
  end

  def handle_event("open_code_editor", %{"nodeId" => node_id, "code" => code}, socket) do
    handle_event(
      "open_code_editor",
      %{
        "nodeId" => node_id,
        "code" => code,
        "fieldName" => "code",
        "language" => "elixir",
        "variables" => []
      },
      socket
    )
  end

  @impl true
  def handle_event(
        "open_code_editor_from_config",
        %{"field-name" => field_name, "code" => code, "language" => language},
        socket
      ) do
    # Determine which code field to populate based on language
    {code_elixir, code_python} =
      case language do
        "python" -> {"", code}
        _ -> {code, ""}
      end

    {:noreply,
     assign(socket,
       modal_open: true,
       current_code_elixir: code_elixir,
       current_code_python: code_python,
       current_code_tab: language,
       current_field_name: field_name,
       current_language: language
     )}
  end

  @impl true
  def handle_event("open_node_config", %{"nodeId" => _node_id, "nodeData" => node_data}, socket) do
    {:noreply,
     assign(socket,
       config_modal_open: true,
       editing_node_data: node_data,
       current_node_id: node_data["id"]
     )}
  end

  @impl true
  def handle_event("close_config_modal", _params, socket) do
    {:noreply,
     assign(socket,
       config_modal_open: false,
       editing_node_data: nil,
       current_node_id: nil
     )}
  end

  @impl true
  def handle_event("save_node_config", params, socket) do
    node_id = socket.assigns.current_node_id
    config_data = Map.drop(params, ["_csrf_token", "_target", "node_label"])
    node_label = params["node_label"]

    socket =
      if node_label && node_label != socket.assigns.editing_node_data["label"] do
        push_event(socket, "update_node_label", %{nodeId: node_id, label: node_label})
      else
        socket
      end

    socket =
      Enum.reduce(config_data, socket, fn {_key, value}, acc_socket ->
        if String.starts_with?(value, "ui do") do
          case FusionFlow.CodeParser.parse_ui_definition(value) do
            {:ok, ui_fields} ->
              inputs =
                Enum.filter(ui_fields, &(&1.type == "input")) |> Enum.map(& &1.name)

              outputs =
                Enum.filter(ui_fields, &(&1.type == "output")) |> Enum.map(& &1.name)

              if inputs != [] or outputs != [] do
                push_event(acc_socket, "update_node_sockets", %{
                  nodeId: node_id,
                  inputs: inputs,
                  outputs: outputs
                })
              else
                acc_socket
              end

            _ ->
              acc_socket
          end
        else
          acc_socket
        end
      end)

    socket =
      socket
      |> push_event("update_node_data", %{nodeId: node_id, data: config_data})
      |> assign(
        config_modal_open: false,
        editing_node_data: nil,
        current_node_id: nil
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_language", %{"lang" => lang}, socket) do
    {:noreply, assign(socket, current_language: lang)}
  end

  @impl true
  def handle_event("switch_code_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, current_code_tab: tab)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     assign(socket,
       modal_open: false,
       current_node_id: nil,
       current_code_elixir: "",
       current_code_python: "",
       current_field_name: nil
     )}
  end

  @impl true
  def handle_event(
        "save_code",
        %{"code_elixir" => code_elixir, "code_python" => code_python},
        socket
      ) do
    node_id = socket.assigns.current_node_id
    field_name = socket.assigns.current_field_name

    socket =
      if socket.assigns.config_modal_open do
        editing_node_data = socket.assigns.editing_node_data

        updated_node_data =
          editing_node_data
          |> put_in(["controls", "code_elixir", "value"], code_elixir)
          |> put_in(["controls", "code_python", "value"], code_python)

        socket
        |> assign(
          modal_open: false,
          current_code_elixir: "",
          current_code_python: "",
          current_field_name: nil,
          editing_node_data: updated_node_data
        )
      else
        socket
        |> push_event("update_node_code", %{
          nodeId: node_id,
          code_elixir: code_elixir,
          code_python: code_python,
          fieldName: field_name
        })
        |> assign(
          modal_open: false,
          current_node_id: nil,
          current_code_elixir: "",
          current_code_python: "",
          current_field_name: nil
        )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("get_node_definition", %{"name" => name}, socket) do
    definition = FusionFlow.Nodes.Registry.get_node(name)
    {:reply, %{definition: definition}, socket}
  end

  @impl true
  def handle_event("parse_node_ui", %{"code" => code}, socket) do
    {:ok, ui_fields} = FusionFlow.CodeParser.parse_ui_definition(code)
    {:reply, %{ui_fields: ui_fields}, socket}
  end

  @impl true
  def handle_event("save_graph", _params, socket) do
    {:noreply, push_event(socket, "request_graph_data", %{})}
  end

  @impl true
  def handle_event("save_graph_data", %{"data" => data}, socket) do
    case FusionFlow.Flows.update_flow(socket.assigns.current_flow, data) do
      {:ok, updated_flow} ->
        {:noreply, assign(socket, current_flow: updated_flow, has_changes: false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save graph data.")}
    end
  end

  @impl true
  def handle_event("open_dependencies_modal", _params, socket) do
    installed = FusionFlow.Dependencies.list_installed_mix_deps()
    {:noreply, assign(socket, dependencies_modal_open: true, installed_deps: installed)}
  end

  @impl true
  def handle_event("close_dependencies_modal", _params, socket) do
    {:noreply,
     assign(socket, dependencies_modal_open: false, search_results: [], search_query: "")}
  end

  @impl true
  def handle_event("switch_dependencies_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, dependencies_tab: tab)}
  end

  @impl true
  def handle_event("search_dependency", %{"query" => query}, socket) do
    if String.length(query) < 2 do
      {:noreply, assign(socket, search_query: query, search_results: [])}
    else
      case FusionFlow.Dependencies.search_hex(query) do
        {:ok, results} ->
          {:noreply, assign(socket, search_query: query, search_results: results)}

        _ ->
          {:noreply, assign(socket, search_query: query, search_results: [])}
      end
    end
  end

  @impl true
  def handle_event("install_dependency", %{"name" => name, "version" => version}, socket) do
    target = self()

    Task.start(fn ->
      case FusionFlow.Dependencies.add_dependency(name, version, "elixir", stream_to: target) do
        {:ok, _} -> send(target, {:dep_install_finished, name})
        {:error, reason} -> send(target, {:dep_install_failed, name, reason})
      end
    end)

    {:noreply,
     assign(socket,
       terminal_logs: ["Starting installation of #{name}...\n"],
       installing_dep: name
     )}
  end

  @impl true
  def handle_event("show_error_details", %{"nodeId" => node_id, "message" => message}, socket) do
    {:noreply,
     assign(socket,
       error_modal_open: true,
       current_error_node_id: node_id,
       current_error_message: message
     )}
  end

  @impl true
  def handle_event("close_error_modal", _params, socket) do
    {:noreply,
     assign(socket,
       error_modal_open: false,
       current_error_node_id: nil,
       current_error_message: nil
     )}
  end

  @impl true
  def handle_event("close_result_modal", _params, socket) do
    {:noreply, assign(socket, show_result_modal: false)}
  end

  @impl true
  def handle_info({:dep_log, message}, socket) do
    current_logs = socket.assigns.terminal_logs
    full_log_check = Enum.join(current_logs ++ [message])

    restart_needed =
      full_log_check =~ "You must restart your server" or
        full_log_check =~ "could not compile application" or
        full_log_check =~ "failure" or
        full_log_check =~ "must be recomputed" or
        full_log_check =~ "server restart"

    pending = socket.assigns.pending_restart_deps

    new_pending =
      if restart_needed and socket.assigns.installing_dep do
        [socket.assigns.installing_dep | pending] |> Enum.uniq()
      else
        pending
      end

    {:noreply,
     assign(socket,
       terminal_logs: current_logs ++ [message],
       pending_restart_deps: new_pending
     )}
  end

  @impl true
  def handle_info({:dep_install_finished, name}, socket) do
    installed = FusionFlow.Dependencies.list_installed_mix_deps()

    msg =
      if name in socket.assigns.pending_restart_deps do
        "Dependency #{name} installed, but a server restart is required."
      else
        "Dependency #{name} installed successfully!"
      end

    type = if name in socket.assigns.pending_restart_deps, do: :warning, else: :info

    {:noreply,
     socket
     |> put_flash(type, msg)
     |> assign(installed_deps: installed, installing_dep: nil)}
  end

  @impl true
  def handle_info({:dep_install_failed, name, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Failed to install #{name}: #{inspect(reason)}")
     |> assign(installing_dep: nil)}
  end

  defp trigger_ai_stream(socket) do
    messages = socket.assigns.chat_messages

    ai_messages =
      Enum.map(messages, fn
        {:user, text} -> %{role: "user", content: text}
        {:ai, text} -> %{role: "assistant", content: text}
      end)

    ai_messages = List.delete_at(ai_messages, -1)

    parent = self()

    socket = assign(socket, chat_loading: true)

    start_async(socket, :ai_stream, fn ->
      current_flow = socket.assigns.current_flow

      case FusionFlow.Agents.FlowCreator.chat(ai_messages, current_flow) do
        {:ok, result} ->
          Enum.reduce_while(result.stream, :ok, fn event, _acc ->
            case event do
              {:text_delta, text} ->
                send(parent, {:chat_stream_chunk, text})
                {:cont, :ok}

              {:error, reason} ->
                send(parent, {:chat_stream_error, reason})
                {:halt, {:error, reason}}

              {:finish, _reason} ->
                {:cont, :ok}

              _ ->
                {:cont, :ok}
            end
          end)

          IO.puts("ASYNC TASK: Stream loop finished")
          :ok

        error ->
          IO.inspect(error, label: "ASYNC TASK: AI Stream Error")
          error
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-[100vh] flex flex-col bg-white dark:bg-slate-900 overflow-hidden relative">
      <header class="flex items-center justify-between px-6 py-3 border-b border-gray-200 dark:border-slate-800 bg-white dark:bg-slate-900 z-10 h-16 shadow-sm">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg shadow-sm">
            <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
          </div>
          
          <div>
            <h1 class="text-base font-bold text-gray-900 dark:text-white leading-tight">
              Flow Editor
            </h1>
            
            <div class="flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
              <p class="text-xs text-gray-500 dark:text-gray-400 font-medium">Active Session</p>
            </div>
          </div>
        </div>
        
        <div class="flex items-center gap-3">
          <!-- Flows Link -->
          <a
            href={~p"/flows"}
            class="h-9 px-3 flex items-center gap-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-slate-800 rounded-md transition-all"
            title="Go to Flows"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
              />
            </svg> <span class="hidden sm:inline">Flows</span>
          </a>
          <div class="h-5 w-px bg-gray-200 dark:bg-slate-700 mx-1"></div>
          
          <button
            phx-click="open_dependencies_modal"
            class="h-9 px-3 flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-md hover:border-indigo-500 dark:hover:border-indigo-500 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
              >
              </path>
            </svg> <span class="hidden sm:inline">Dependencies</span>
          </button>
          <button
            phx-click="run_flow"
            class="h-9 px-4 flex items-center gap-2 text-sm font-semibold text-white bg-green-600 hover:bg-green-700 rounded-md transition-colors shadow-none hover:shadow-none"
          >
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                clip-rule="evenodd"
              />
            </svg> <span>Run Flow</span>
          </button>
        </div>
      </header>
      
      <div class="flex-1 flex overflow-hidden">
        <aside class="w-64 bg-gray-50 dark:bg-slate-800 border-r border-gray-200 dark:border-slate-700 flex flex-col z-10">
          <div class="p-4 border-b border-gray-200 dark:border-slate-700">
            <h2 class="text-sm font-semibold text-gray-500 dark:text-slate-400 uppercase tracking-wider">
              Nodes
            </h2>
          </div>
          
          <div class="flex-1 overflow-y-auto p-4 space-y-5">
            <%= for {category, nodes} <- @nodes_by_category do %>
              <% {label, color_class} = category_meta(category) %>
              <div>
                <h3 class="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-wider mb-2 px-1">
                  {label}
                </h3>
                
                <div class="space-y-1.5">
                  <%= for node <- nodes do %>
                    <button
                      phx-click="add_node"
                      phx-value-name={node.name}
                      class="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg shadow-sm hover:bg-gray-50 dark:hover:bg-slate-600 hover:border-indigo-700 dark:hover:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-offset-1 focus:ring-indigo-700 dark:focus:ring-indigo-500 cursor-pointer transition-all"
                    >
                      <span class={"w-5 h-5 rounded flex items-center justify-center text-xs #{color_class}"}>
                        {node.icon}
                      </span> {node.name}
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </aside>
        
        <div
          class="flex-1 relative bg-gray-100 dark:bg-slate-900"
          id="rete-container"
          phx-update="ignore"
        >
          <div
            id="rete"
            class="absolute inset-0 w-full h-full"
            phx-hook="Rete"
          >
          </div>
        </div>
      </div>
      
      <%= if @has_changes do %>
        <div class="absolute bottom-6 left-1/2 transform -translate-x-1/2 bg-white px-6 py-3 rounded-full shadow-lg border border-gray-200 z-50 flex items-center gap-4 animate-bounce-in">
          <span class="text-sm font-medium text-gray-700">You have unsaved changes</span>
          <button
            phx-click="save_graph"
            class="px-4 py-1.5 bg-indigo-600 text-white text-sm font-semibold rounded-full hover:bg-indigo-700 transition"
          >
            Save Changes
          </button>
        </div>
      <% end %>
      
      <%= if @modal_open do %>
        <div class="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-2xl w-full max-w-4xl flex flex-col h-[80vh] border border-gray-200 dark:border-slate-700 animate-in fade-in zoom-in duration-200">
            <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-slate-700">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-slate-100 flex items-center gap-2">
                <span class="p-1 rounded bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                    />
                  </svg>
                </span>
                Edit Code
              </h3>
              
              <button
                phx-click="close_modal"
                class="text-gray-400 hover:text-gray-500 transition-colors"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            
            <div class="flex border-b border-gray-200 dark:border-slate-700 px-6 bg-gray-50 dark:bg-slate-800/50">
              <button
                type="button"
                phx-click="switch_code_tab"
                phx-value-tab="elixir"
                class={"px-4 py-3 text-sm font-medium border-b-2 -mb-px #{if @current_code_tab == "elixir", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                <span class="flex items-center gap-2">
                  <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C8.5 6 6 10 6 14.5C6 18.09 8.69 21 12 21C15.31 21 18 18.09 18 14.5C18 10 15.5 6 12 2Z" />
                  </svg>
                  Elixir
                </span>
              </button>
              <button
                type="button"
                phx-click="switch_code_tab"
                phx-value-tab="python"
                class={"px-4 py-3 text-sm font-medium border-b-2 -mb-px #{if @current_code_tab == "python", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                <span class="flex items-center gap-2">
                  <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
                  </svg>
                  Python
                </span>
              </button>
            </div>
            
            <form phx-submit="save_code" class="flex-1 flex flex-col overflow-hidden">
              <div
                class="flex-1 p-0 overflow-hidden relative bg-[#1e1e1e]"
                id="code-editor-wrapper"
                phx-update="ignore"
                phx-hook="CodeEditor"
                data-variables={Jason.encode!(@available_variables)}
                data-language={@current_code_tab}
              >
                <textarea
                  id="code_elixir_textarea"
                  name="code_elixir"
                  class="w-full h-full hidden"
                ><%= @current_code_elixir %></textarea> <textarea
                  id="code_python_textarea"
                  name="code_python"
                  class="w-full h-full hidden"
                ><%= @current_code_python %></textarea>
              </div>
              
              <div class="px-6 py-4 bg-white dark:bg-slate-800 border-t border-gray-200 dark:border-slate-700 flex justify-end gap-3 rounded-b-lg">
                <button
                  type="button"
                  phx-click="close_modal"
                  class="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg shadow-sm hover:bg-gray-50 dark:hover:bg-slate-600 transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="flex items-center gap-2 px-5 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 border border-transparent rounded-lg shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
      <%= if @config_modal_open do %>
        <div class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-2xl w-full max-w-lg flex flex-col max-h-[90vh] border border-gray-200 dark:border-slate-700 animate-in fade-in zoom-in duration-200">
            <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-slate-700">
              <h3 class="text-xl font-bold text-gray-900 dark:text-slate-100 tracking-tight flex items-center gap-2">
                <span class="p-1.5 rounded-lg bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"
                    />
                  </svg>
                </span>
                Configure {@editing_node_data["label"]}
              </h3>
              
              <button
                phx-click="close_config_modal"
                class="text-gray-400 hover:text-gray-500 transition-colors"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            
            <form phx-submit="save_node_config" class="flex-1 flex flex-col overflow-hidden">
              <div class="flex-1 p-6 overflow-y-auto space-y-6">
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-gray-700 dark:text-slate-300">
                    Node Name
                  </label>
                  <input
                    type="text"
                    name="node_label"
                    value={@editing_node_data["label"]}
                    class="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 dark:bg-slate-900 dark:text-white transition-all h-10"
                  />
                </div>
                
                <%= if @editing_node_data["controls"] do %>
                  <%= for {key, control} <- @editing_node_data["controls"] do %>
                    <div class="space-y-2">
                      <label class="block text-sm font-semibold text-gray-700 dark:text-slate-300 capitalize">
                        {control["label"] || String.replace(key, "_", " ")}
                      </label>
                      <%= case control["type"] do %>
                        <% "select" -> %>
                          <select
                            name={key}
                            class="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 dark:bg-slate-900 dark:text-white transition-all h-10"
                          >
                            <%= for option <- (control["options"] || []) do %>
                              <%= if is_map(option) do %>
                                <option
                                  value={option["value"]}
                                  selected={option["value"] == control["value"]}
                                >
                                  {option["label"]}
                                </option>
                              <% else %>
                                <option value={option} selected={option == control["value"]}>
                                  {option}
                                </option>
                              <% end %>
                            <% end %>
                          </select>
                        <% "code-icon" -> %>
                          <div class="relative group">
                            <textarea
                              name={key}
                              rows="3"
                              readonly
                              class="w-full px-3 py-2 font-mono text-sm text-gray-500 border border-gray-300 dark:border-slate-600 rounded-lg bg-gray-50 dark:bg-slate-900 dark:text-gray-400 cursor-not-allowed resize-none"
                            >{control["value"]}</textarea>
                            <button
                              type="button"
                              phx-click="open_code_editor_from_config"
                              phx-value-field-name={key}
                              phx-value-code={control["value"]}
                              phx-value-language={control["language"] || "elixir"}
                              class="absolute top-2 right-2 p-1.5 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-600 rounded-md shadow-sm hover:border-primary-500 text-gray-500 hover:text-primary-600 transition-all"
                              title="Open Code Editor"
                            >
                              <svg
                                class="w-4 h-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                                />
                              </svg>
                            </button>
                          </div>
                        <% "code-button" -> %>
                          <div class="flex items-center gap-3 p-3 border border-gray-200 dark:border-slate-700 rounded-lg bg-gray-50 dark:bg-slate-800/50">
                            <div class="flex-1">
                              <div class="text-xs font-mono text-gray-500 dark:text-gray-400 truncate">
                                {String.slice(control["value"] || "", 0, 50)}...
                              </div>
                            </div>
                            
                            <button
                              type="button"
                              phx-click="open_code_editor_from_config"
                              phx-value-field-name={key}
                              phx-value-code={control["value"]}
                              phx-value-language={control["language"] || "elixir"}
                              class="flex items-center gap-2 px-3 py-1.5 text-xs font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm transition-all"
                            >
                              <svg
                                class="w-3.5 h-3.5"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                                />
                              </svg>
                              Edit Code
                            </button> <input type="hidden" name={key} value={control["value"]} />
                          </div>
                        <% _ -> %>
                          <%= if String.length(to_string(control["value"])) > 50 do %>
                            <textarea
                              name={key}
                              rows="4"
                              class="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 dark:bg-slate-900 dark:text-white transition-all"
                            >{control["value"]}</textarea>
                          <% else %>
                            <input
                              type="text"
                              name={key}
                              value={control["value"]}
                              class="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 dark:bg-slate-900 dark:text-white transition-all h-10"
                            />
                          <% end %>
                      <% end %>
                    </div>
                  <% end %>
                <% else %>
                  <p class="text-gray-500 dark:text-gray-400 italic">
                    No configuration options available for this node.
                  </p>
                <% end %>
              </div>
              
              <div class="px-6 py-5 bg-white dark:bg-slate-800 border-t border-gray-200 dark:border-slate-700 flex justify-end gap-3 rounded-b-lg">
                <button
                  type="button"
                  phx-click="close_config_modal"
                  class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-slate-300 bg-white dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg shadow-sm hover:bg-gray-50 dark:hover:bg-slate-600 transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-5 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 border border-transparent rounded-lg shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all transform active:scale-95"
                >
                  Save Configuration
                </button>
              </div>
            </form>
          </div>
        </div>
      <% end %>
      
      <%= if @error_modal_open do %>
        <div class="fixed inset-0 z-[120] flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-2xl w-full max-w-2xl flex flex-col max-h-[80vh] border border-red-200 dark:border-red-900 animate-in fade-in zoom-in duration-200">
            <div class="flex items-center justify-between px-6 py-4 border-b border-red-100 dark:border-red-900/50 bg-red-50 dark:bg-red-900/10 rounded-t-lg">
              <h3 class="text-lg font-bold text-red-700 dark:text-red-400 flex items-center gap-2">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                Node Execution Error
              </h3>
              
              <button
                phx-click="close_error_modal"
                class="text-red-400 hover:text-red-600 dark:hover:text-red-300 transition-colors"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            
            <div class="p-6 overflow-y-auto">
              <div class="mb-4">
                <p class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Node ID:</p>
                
                <code class="px-2 py-1 bg-gray-100 dark:bg-slate-900 rounded text-sm text-gray-700 dark:text-gray-300 font-mono">
                  {@current_error_node_id}
                </code>
              </div>
              
              <div>
                <p class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">
                  Error Message:
                </p>
                
                <div class="p-4 bg-gray-50 dark:bg-slate-900/50 rounded-lg border border-gray-200 dark:border-slate-700 overflow-x-auto">
                  <pre class="text-sm text-red-600 dark:text-red-400 font-mono whitespace-pre-wrap">{@current_error_message}</pre>
                </div>
              </div>
            </div>
            
            <div class="px-6 py-4 border-t border-gray-200 dark:border-slate-700 flex justify-end">
              <button
                phx-click="close_error_modal"
                class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      <% end %>
      
      <%= if @dependencies_modal_open do %>
        <div class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-4xl flex flex-col max-h-[90vh]">
            <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
                Project Dependencies
              </h3>
              
              <button phx-click="close_dependencies_modal" class="text-gray-400 hover:text-gray-500">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            
            <div class="flex border-b border-gray-200 dark:border-gray-700 px-6 pt-2">
              <button
                phx-click="switch_dependencies_tab"
                phx-value-tab="elixir"
                class={"px-4 py-2.5 text-sm font-medium border-b-2 -mb-px #{if @dependencies_tab == "elixir", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                Elixir (Hex)
              </button>
              <button
                phx-click="switch_dependencies_tab"
                phx-value-tab="python"
                class={"px-4 py-2.5 text-sm font-medium border-b-2 -mb-px #{if @dependencies_tab == "python", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                Python (Pip)
              </button>
              <button
                phx-click="switch_dependencies_tab"
                phx-value-tab="javascript"
                class={"px-4 py-2.5 text-sm font-medium border-b-2 -mb-px #{if @dependencies_tab == "javascript", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
              >
                JavaScript (NPM)
              </button>
            </div>
            
            <div class="p-6 flex-1 overflow-y-auto">
              <%= if @dependencies_tab == "elixir" do %>
                <div class="space-y-6">
                  <%= if @pending_restart_deps != [] do %>
                    <div class="bg-yellow-50 dark:bg-yellow-900/30 border-l-4 border-yellow-400 p-4 mb-4">
                      <div class="flex">
                        <div class="flex-shrink-0">
                          <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                            <path
                              fill-rule="evenodd"
                              d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                              clip-rule="evenodd"
                            />
                          </svg>
                        </div>
                        
                        <div class="ml-3">
                          <p class="text-sm text-yellow-700 dark:text-yellow-200">
                            The following dependencies require a server restart: <span class="font-bold"><%= Enum.join(@pending_restart_deps, ", ") %></span>.
                            Please restart your application.
                          </p>
                        </div>
                      </div>
                    </div>
                  <% end %>
                  
                  <div class="relative">
                    <form phx-submit="search_dependency" phx-change="search_dependency">
                      <input
                        type="text"
                        name="query"
                        value={@search_query}
                        placeholder="Search packages on Hex.pm..."
                        class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                        phx-debounce="500"
                      />
                      <svg
                        class="w-5 h-5 text-gray-400 absolute left-3 top-2.5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                        >
                        </path>
                      </svg>
                    </form>
                  </div>
                  
                  <%= if @search_results != [] do %>
                    <div>
                      <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                        Search Results
                      </h4>
                      
                      <div class="grid grid-cols-1 gap-3">
                        <%= for pkg <- @search_results do %>
                          <div class="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50">
                            <div>
                              <div class="flex items-center gap-2">
                                <span class="font-bold text-gray-900 dark:text-white">
                                  {pkg.name}
                                </span>
                                <span class="text-xs bg-indigo-100 text-indigo-800 px-2 py-0.5 rounded-full">
                                  {pkg.latest_version}
                                </span>
                              </div>
                              
                              <p class="text-sm text-gray-500 mt-1 line-clamp-1">{pkg.description}</p>
                            </div>
                            
                            <%= if pkg.name in @pending_restart_deps do %>
                              <button
                                disabled
                                class="px-3 py-1.5 text-xs font-medium bg-yellow-500 text-white rounded cursor-not-allowed opacity-80"
                              >
                                Restart Required
                              </button>
                            <% else %>
                              <button
                                phx-click="install_dependency"
                                phx-value-name={pkg.name}
                                phx-value-version={pkg.latest_version}
                                class="px-3 py-1.5 text-xs font-medium bg-indigo-600 text-white rounded hover:bg-indigo-700 transition"
                              >
                                Install
                              </button>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                  
                  <div>
                    <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                      Installed in mix.exs
                    </h4>
                    
                    <div class="border rounded-lg overflow-hidden border-gray-200 dark:border-gray-700">
                      <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead class="bg-gray-50 dark:bg-gray-800">
                          <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              Name
                            </th>
                            
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              Version
                            </th>
                            
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                              Action
                            </th>
                          </tr>
                        </thead>
                        
                        <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                          <%= for dep <- @installed_deps do %>
                            <tr>
                              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                                {dep.name}
                              </td>
                              
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                {dep.version}
                              </td>
                              
                              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <%= if dep.name in @pending_restart_deps do %>
                                  <span class="text-yellow-600 font-bold flex justify-end gap-1 items-center">
                                    <svg
                                      class="w-4 h-4"
                                      fill="none"
                                      stroke="currentColor"
                                      viewBox="0 0 24 24"
                                    >
                                      <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                      />
                                    </svg>
                                    Restart Required
                                  </span>
                                <% else %>
                                  <span class="text-green-600">Installed</span>
                                <% end %>
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="flex flex-col items-center justify-center h-48 text-gray-500">
                  <svg
                    class="w-12 h-12 mb-4 text-gray-300"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                    >
                    </path>
                  </svg>
                  <p>Support for {@dependencies_tab} dependencies coming soon.</p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
      <!-- Execution Result Modal -->
      <%= if @show_result_modal do %>
        <div class="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div class="bg-white dark:bg-slate-800 rounded-lg shadow-xl w-3/4 max-w-2xl max-h-[80vh] flex flex-col border border-gray-200 dark:border-slate-700 animate-in fade-in zoom-in duration-200">
            <div class="flex items-center justify-between p-4 border-b border-gray-200 dark:border-slate-700">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Execution Result</h3>
              
              <button
                phx-click="close_result_modal"
                class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  >
                  </path>
                </svg>
              </button>
            </div>
            
            <div class="p-6 overflow-y-auto max-h-[60vh] bg-white dark:bg-slate-900">
              <%= if @execution_result && map_size(@execution_result) > 0 do %>
                <div class="space-y-4">
                  <%= for {key, value} <- Enum.sort(@execution_result) do %>
                    <%= if is_binary(key) and not String.starts_with?(key, "flow_") do %>
                      <div class="flex flex-col sm:flex-row sm:items-start gap-2 p-3 rounded-lg bg-gray-50 dark:bg-slate-800/50 border border-gray-100 dark:border-slate-700/50 hover:border-indigo-200 dark:hover:border-indigo-800 transition-colors">
                        <div class="sm:w-1/3 min-w-[120px]">
                          <span class="text-sm font-semibold text-gray-700 dark:text-slate-300 break-words">
                            {key}
                          </span>
                        </div>
                        
                        <div class="flex-1 min-w-0">
                          <div class="text-sm text-gray-900 dark:text-slate-100 font-mono bg-white dark:bg-slate-950 rounded px-2 py-1 border border-gray-200 dark:border-slate-700 overflow-x-auto">
                            <%= if is_binary(value) do %>
                              {value}
                            <% else %>
                              {inspect(value, pretty: true, limit: :infinity)}
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center py-12">
                  <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-gray-100 dark:bg-slate-800 mb-4">
                    <svg
                      class="w-6 h-6 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                      />
                    </svg>
                  </div>
                  
                  <h3 class="text-base font-medium text-gray-900 dark:text-slate-200">
                    No output data
                  </h3>
                  
                  <p class="mt-1 text-sm text-gray-500 dark:text-slate-400">
                    The flow finished without producing any visible output.
                  </p>
                </div>
              <% end %>
            </div>
            
            <div class="p-4 border-t border-gray-200 dark:border-slate-700 flex justify-end">
              <button
                phx-click="close_result_modal"
                class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      <% end %>
      
      <.live_component
        module={FusionFlowWeb.Components.ChatComponent}
        id="chat-component"
        open={@chat_open}
        messages={@chat_messages}
        loading={@chat_loading}
        ai_configured={@ai_configured}
        on_toggle="toggle_chat"
        on_send="send_message"
      />
    </div>
    """
  end

  defp category_meta(:trigger), do: {"Triggers", "bg-green-100 text-green-600"}
  defp category_meta(:flow_control), do: {"Flow Control", "bg-yellow-100 text-yellow-600"}
  defp category_meta(:code), do: {"Code", "bg-indigo-100 text-indigo-700"}
  defp category_meta(:integration), do: {"Integration", "bg-orange-100 text-orange-600"}
  defp category_meta(:data_manipulation), do: {"Data", "bg-blue-100 text-blue-600"}
  defp category_meta(:utility), do: {"Utility", "bg-gray-100 text-gray-600"}
  defp category_meta(_), do: {"Other", "bg-gray-100 text-gray-600"}

  defp language_config("elixir") do
    {"Elixir",
     ~s|<path d="M12 2C8.5 6 6 10 6 14.5C6 18.09 8.69 21 12 21C15.31 21 18 18.09 18 14.5C18 10 15.5 6 12 2Z" />|}
  end

  defp language_config("sql") do
    {"SQL",
     ~s|<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-5.5-2.5l7.51-3.22-7.52-3.22 7.52-3.22L6.5 4.78 6.5 17.5z"/>|}
  end

  defp language_config("javascript") do
    {"JavaScript",
     ~s|<path d="M3 3h18v18H3V3zm13.15 13.78c.31-.6.41-1.12.39-1.57-.03-.43-.22-.76-.55-1.01-.33-.25-.82-.47-1.46-.66-.64-.19-1.28-.41-1.92-.66-.63-.25-1.07-.64-1.31-1.17-.23-.53-.2-1.14.08-1.83.29-.7.82-1.2 1.58-1.51.76-.31 1.62-.35 2.58-.12.96.23 1.76.7 2.41 1.41.65.71.95 1.55.9 2.52h-2.18c.03-.45-.09-.8-.36-1.04-.27-.24-.65-.33-1.14-.26-.49.07-.85.25-1.1.55-.25.3-.28.67-.09 1.1s.59.74 1.2 1.05c.61.31 1.23.57 1.86.77.63.2 1.17.51 1.62.94.45.43.71.98.8 1.65.09.67.0 1.34-.36 1.95-.36.61-.95 1.05-1.77 1.33-.82.28-1.75.32-2.79.13-1.04-.19-1.93-.61-2.67-1.26-.74-.65-1.16-1.47-1.27-2.46h2.24c.05.46.22.82.52 1.07.3.25.72.36 1.27.32.55-.04.97-.22 1.27-.55.3-.33.4-.73.3-1.2z"/>|}
  end

  defp language_config("python") do
    {"Python",
     ~s|<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />|}
  end

  defp language_config(_),
    do:
      {"Text",
       ~s|<path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/>|}

  def handle_info({:chat_stream_chunk, chunk}, socket) do
    messages = socket.assigns.chat_messages
    {last_role, last_content} = List.last(messages)

    updated_messages =
      if last_role == :ai do
        List.replace_at(messages, -1, {:ai, last_content <> chunk})
      else
        messages
      end

    {:noreply, assign(socket, chat_messages: updated_messages)}
  end

  def handle_info({:chat_stream_error, reason}, socket) do
    {:noreply, put_flash(socket, :error, "AI Error: #{inspect(reason)}")}
  end

  def handle_async(:ai_stream, {:ok, :ok}, socket) do
    {:noreply, socket}
  end

  def handle_async(:ai_stream, {:ok, error}, socket) do
    IO.inspect(error, label: "AI Stream Async Result Error")
    {:noreply, put_flash(socket, :error, "AI Error: #{inspect(error)}")}
  end

  def handle_async(:ai_stream, {:exit, reason}, socket) do
    {:noreply, put_flash(socket, :error, "AI Stream failed: #{inspect(reason)}")}
  end
end
