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
       renaming_flow: false,
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
       execution_result: nil,
       show_result_modal: false,
       error_modal_open: false,
       current_error_message: nil,
       current_error_node_id: nil,
       available_variables: [],
       chat_open: false,
       chat_messages: [],
       pending_ai_trigger: false,
       chat_loading: false,
       ai_configured: System.get_env("OPENAI_API_KEY") not in [nil, ""],
       inspecting_result: false
     ), layout: false}
  end

  @impl true
  def handle_event("change_locale", %{"locale" => locale}, socket) do
    {:noreply, redirect(socket, to: ~p"/?locale=#{locale}")}
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
  def handle_event("node_added_internally", %{"name" => _name, "data" => _data}, socket) do
    # At this point the node is already rendered in JS.
    # We just need to flag it as changed here:
    {:noreply, assign(socket, has_changes: true)}
  end

  @impl true
  def handle_event("show_drag_tooltip", %{"name" => name}, socket) do
    {:noreply,
     put_flash(socket, :info, "Drag and drop the '#{name}' node onto the canvas to add it.")}
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
  def handle_event("toggle_chat", _params, socket) do
    {:noreply, assign(socket, chat_open: !socket.assigns.chat_open)}
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
  def handle_event("send_message", %{"content" => content}, socket) do
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
      current_flow = socket.assigns.current_flow

      socket =
        start_async(socket, :ai_stream, fn ->
          {:ok, result} = FusionFlow.Agents.FlowCreator.chat(ai_messages, current_flow)

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

          :ok
        end)

      {:noreply, socket}
    end
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
          {:ok, ui_fields} = FusionFlow.CodeParser.parse_ui_definition(value)

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
        current_node_id: nil,
        inspecting_result: false
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
  def handle_event("edit_flow_name", _params, socket) do
    {:noreply, assign(socket, renaming_flow: true)}
  end

  @impl true
  def handle_event("cancel_rename_flow", _params, socket) do
    {:noreply, assign(socket, renaming_flow: false)}
  end

  @impl true
  def handle_event("save_flow_name", %{"name" => new_name}, socket) do
    if String.trim(new_name) != "" do
      case FusionFlow.Flows.update_flow(socket.assigns.current_flow, %{name: new_name}) do
        {:ok, updated_flow} ->
          {:noreply, assign(socket, current_flow: updated_flow, renaming_flow: false)}

        {:error, _} ->
          {:noreply,
           assign(socket, renaming_flow: false) |> put_flash(:error, "Failed to rename flow")}
      end
    else
      {:noreply, assign(socket, renaming_flow: false)}
    end
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
    {:noreply, assign(socket, show_result_modal: false, inspecting_result: false)}
  end

  @impl true
  def handle_event("toggle_inspect_result", _params, socket) do
    {:noreply, assign(socket, inspecting_result: !socket.assigns.inspecting_result)}
  end

  @impl true
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

                # Map generic 'code' from AI to 'code_elixir' for Evaluate Code nodes
                controls =
                  if node["type"] == "Evaluate Code" or node["name"] == "Evaluate Code" do
                    code_val = controls["code"] || controls["code_elixir"]

                    if code_val do
                      controls
                      |> Map.put("code_elixir", code_val)
                      |> Map.delete("code")
                    else
                      controls
                    end
                  else
                    controls
                  end

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

  @impl true
  def handle_async(:ai_stream, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "AI Stream failed: #{inspect(reason)}")
     |> assign(chat_loading: false)}
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

  @impl true
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

  @impl true
  def handle_info({:chat_stream_error, reason}, socket) do
    {:noreply, put_flash(socket, :error, "AI Error: #{inspect(reason)}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-[100vh] flex flex-col bg-white dark:bg-slate-950 overflow-hidden relative">
      <FusionFlowWeb.Components.Flow.FlowHeader.flow_header
        has_changes={@has_changes}
        flow={@current_flow}
        renaming_flow={@renaming_flow}
      />
      <div class="flex-1 flex overflow-hidden">
        <FusionFlowWeb.Components.Flow.NodeSidebar.node_sidebar nodes_by_category={@nodes_by_category} />
        <script>
          window.Translations = {
            "Run": "<%= gettext("Run") %>",
            "Waiting...": "<%= gettext("Waiting...") %>",
            "Remove Node": "<%= gettext("Remove Node") %>",
            "Configure Node": "<%= gettext("Configure Node") %>",
            "View Error": "<%= gettext("View Error") %>",
            "Edit Code": "<%= gettext("Edit Code") %>",
            "Coming Soon": "<%= gettext("Coming Soon") %>",
            "Select Integration": "<%= gettext("Select Integration") %>",
            "Drag to canvas": "<%= gettext("Drag to canvas") %>"
          };
        </script>

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

      <FusionFlowWeb.Components.Modals.CodeEditorModal.code_editor_modal
        modal_open={@modal_open}
        current_code_tab={@current_code_tab}
        current_code_elixir={@current_code_elixir}
        current_code_python={@current_code_python}
        available_variables={@available_variables}
      />
      <FusionFlowWeb.Components.Modals.NodeConfigModal.node_config_modal
        config_modal_open={@config_modal_open}
        editing_node_data={@editing_node_data}
      />
      <FusionFlowWeb.Components.Modals.ErrorModal.error_modal
        error_modal_open={@error_modal_open}
        current_error_node_id={@current_error_node_id}
        current_error_message={@current_error_message}
      />
      <FusionFlowWeb.Components.Modals.DependenciesModal.dependencies_modal
        dependencies_modal_open={@dependencies_modal_open}
        dependencies_tab={@dependencies_tab}
        pending_restart_deps={@pending_restart_deps}
        search_query={@search_query}
        search_results={@search_results}
        installed_deps={@installed_deps}
        installing_dep={@installing_dep}
        terminal_logs={@terminal_logs}
      />
      <FusionFlowWeb.Components.Modals.ExecutionResultModal.execution_result_modal
        show_result_modal={@show_result_modal}
        execution_result={@execution_result}
        inspecting_result={@inspecting_result}
      />
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
end
