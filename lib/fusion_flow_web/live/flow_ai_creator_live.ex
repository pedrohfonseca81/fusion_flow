defmodule FusionFlowWeb.FlowAiCreatorLive do
  use FusionFlowWeb, :live_view

  alias FusionFlow.Flows
  alias FusionFlow.Agents.FlowPlanner

  @impl true
  def mount(_params, _session, socket) do
    ai_configured? = System.get_env("OPENAI_API_KEY") not in [nil, ""]

    if ai_configured? do
      {:ok,
       assign(socket,
         page_title: gettext("Create Flow with AI"),
         messages: [],
         loading: false,
         ai_awaiting_approval: false,
         temp_flow_data: nil,
         ai_configured: true
       )}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("OpenAI API Key is not configured."))
       |> push_navigate(to: ~p"/flows")
       |> assign(ai_configured: false)}
    end
  end

  @impl true
  def handle_event("change_locale", %{"locale" => locale}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/flows/new/ai?locale=#{locale}")}
  end

  @impl true
  def handle_event("send_message", %{"content" => content}, socket) do
    if content == "" do
      {:noreply, socket}
    else
      messages = socket.assigns.messages ++ [{:user, content}, {:ai, ""}]

      ai_messages =
        Enum.map(messages, fn
          {:user, text} -> %{role: "user", content: text}
          {:ai, text} -> %{role: "assistant", content: text}
        end)
        |> List.delete_at(-1)

      socket =
        assign(socket,
          messages: messages,
          loading: true,
          ai_awaiting_approval: false,
          temp_flow_data: nil
        )

      parent = self()
      locale = socket.assigns.locale

      socket =
        start_async(socket, :ai_stream, fn ->
          {:ok, result} = FlowPlanner.chat(ai_messages, nil, locale)

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
  def handle_event("approve_plan", _params, socket) do
    content = "Looks good! Please generate the final flow JSON now."
    messages = socket.assigns.messages ++ [{:user, content}, {:ai, ""}]

    ai_messages =
      Enum.map(messages, fn
        {:user, text} -> %{role: "user", content: text}
        {:ai, text} -> %{role: "assistant", content: text}
      end)
      |> List.delete_at(-1)

    socket = assign(socket, messages: messages, loading: true, ai_awaiting_approval: false)
    parent = self()
    locale = socket.assigns.locale

    socket =
      start_async(socket, :ai_stream_json, fn ->
        {:ok, result} = FlowPlanner.chat(ai_messages, nil, locale)

        full_reply =
          Enum.reduce_while(result.stream, "", fn event, acc ->
            case event do
              {:text_delta, text} ->
                send(parent, {:chat_stream_chunk, text})
                {:cont, acc <> text}

              _ ->
                {:cont, acc}
            end
          end)

        {:ok, full_reply}
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_stream_chunk, text}, socket) do
    messages = socket.assigns.messages
    {_last_role, last_content} = List.last(messages)
    updated_messages = List.replace_at(messages, -1, {:ai, last_content <> text})
    {:noreply, assign(socket, messages: updated_messages)}
  end

  @impl true
  def handle_info({:chat_stream_error, reason}, socket) do
    error_msg = if is_binary(reason), do: reason, else: inspect(reason)
    messages = socket.assigns.messages
    updated_messages = List.replace_at(messages, -1, {:error, "Error: #{error_msg}"})
    {:noreply, assign(socket, messages: updated_messages, loading: false)}
  end

  @impl true
  def handle_async(:ai_stream, {:ok, _result}, socket) do
    {_role, last_content} = List.last(socket.assigns.messages)

    socket = parse_and_create_flow_if_json(last_content, socket)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:ai_stream_json, {:ok, {:ok, full_reply}}, socket) do
    socket = parse_and_create_flow_if_json(full_reply, socket)
    {:noreply, socket}
  end

  @impl true
  def handle_async(_key, {:exit, _reason}, socket) do
    {:noreply, assign(socket, loading: false)}
  end

  defp parse_and_create_flow_if_json(content, socket) do
    case Regex.run(~r/\{[\s\S]*"action":\s*"create_flow"[\s\S]*\}/m, content) do
      [json_candidate] ->
        case Jason.decode(json_candidate) do
          {:ok, json_data} ->
            flow_name = "AI Generated Flow #{System.unique_integer([:positive])}"

            # Normalize nodes to ensure compatibility with Rete.js editor
            nodes =
              json_data
              |> Map.get("nodes", [])
              |> Enum.map(fn node ->
                node
                |> Map.put_new("type", Map.get(node, "name"))
                |> Map.update("controls", %{}, fn controls ->
                  case Map.get(node, "type") || Map.get(node, "name") do
                    "Evaluate Code" ->
                      controls
                      |> Map.put_new("language", "elixir")
                      |> Map.put_new("code_elixir", Map.get(controls, "code", ""))
                      |> Map.put_new("code_python", "")

                    "Output" ->
                      controls
                      |> Map.put_new("status", "success")
                      |> Map.put_new(
                        "code",
                        "ui do\n  text :status, label: \"Final Status\", default: \"success\"\nend\n"
                      )

                    _ ->
                      controls
                  end
                end)
              end)

            create_attrs = %{
              name: flow_name,
              nodes: nodes,
              connections: Map.get(json_data, "connections", [])
            }

            case Flows.create_flow(create_attrs) do
              {:ok, new_flow} ->
                socket
                |> put_flash(:info, gettext("Flow built successfully!"))
                |> push_navigate(to: ~p"/flows/#{new_flow}")

              {:error, _} ->
                assign(socket,
                  messages:
                    socket.assigns.messages ++ [{:error, "Failed to persist flow in database"}],
                  loading: false
                )
            end

          {:error, _} ->
            handle_regular_message(content, socket)
        end

      nil ->
        handle_regular_message(content, socket)
    end
  end

  defp handle_regular_message(content, socket) do
    has_marker? = String.contains?(String.upcase(content), "PLAN_PROPOSED")

    if has_marker? do
      messages = socket.assigns.messages
      updated_messages = List.replace_at(messages, -1, {:ai, content})

      assign(socket, messages: updated_messages, loading: false, ai_awaiting_approval: true)
    else
      assign(socket, loading: false, ai_awaiting_approval: false)
    end
  end

  defp markdown(nil), do: ""

  defp markdown(content) do
    content
    |> String.replace(~r/\[?PLAN_PROPOSED\]?/i, "")
    |> Earmark.as_html!()
    |> raw()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full w-full flex flex-col bg-gray-50 dark:bg-slate-900 overflow-hidden">
      <div class="p-6 md:p-8 flex-shrink-0 border-b border-gray-200 dark:border-slate-800 bg-white dark:bg-slate-900">
        <div class="max-w-4xl mx-auto flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
              />
            </svg>
          </div>
          
          <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
              {gettext("Create Flow with AI")}
            </h1>
            
            <p class="text-sm text-gray-500 dark:text-slate-400 mt-1">
              {gettext(
                "Describe what you want to automate, and I will build the flow structure for you."
              )}
            </p>
          </div>
        </div>
      </div>
      
      <div
        class="flex-1 overflow-y-auto w-full p-4 md:p-8 scroll-smooth"
        id="ai-chat-messages"
        phx-hook="ScrollToBottom"
      >
        <div class="max-w-4xl mx-auto space-y-6 pb-20">
          <%= if Enum.empty?(@messages) do %>
            <div class="flex flex-col items-center justify-center h-full text-center text-gray-500 py-20">
              <svg
                class="w-16 h-16 text-indigo-200 dark:text-indigo-900/50 mb-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
                />
              </svg>
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">
                {gettext("How can I help you today?")}
              </h3>
              
              <p class="text-sm mt-2 max-w-sm">
                {gettext(
                  "For example: 'Create a flow that listens to a webhook, logs the payload and saves it into the database.'"
                )}
              </p>
            </div>
          <% end %>
          
          <%= for {role, content} <- @messages, not (role == :ai and content == "") do %>
            <div class={"flex w-full " <> if(role == :user, do: "justify-end", else: "justify-start")}>
              <div class={"max-w-[85%] rounded-2xl px-5 py-4 text-sm leading-relaxed prose prose-sm dark:prose-invert " <>
                  if(role == :user,
                    do: "bg-indigo-600 text-white rounded-br-none shadow-sm dark:shadow-none",
                    else: "bg-white dark:bg-slate-800 text-gray-800 dark:text-gray-200 rounded-bl-none border border-gray-200 dark:border-slate-700 shadow-sm dark:shadow-none")}>
                <%= if String.contains?(content, "\"action\": \"create_flow\"") or String.starts_with?(String.trim(content), "{") do %>
                  <div class="flex items-center gap-2 text-indigo-600 dark:text-indigo-400 font-medium italic animate-pulse">
                    <.icon name="hero-arrow-path" class="w-5 h-5 animate-spin" />{gettext(
                      "Building flow and rendering graph..."
                    )}
                  </div>
                <% else %>
                  {markdown(content)}
                <% end %>
              </div>
            </div>
          <% end %>
          
          <%= if @loading and (List.last(@messages) |> elem(1)) == "" do %>
            <div class="flex justify-start w-full">
              <div class="max-w-[85%] rounded-2xl px-5 py-4 text-sm bg-white dark:bg-slate-800 text-gray-800 dark:text-gray-200 rounded-bl-none border border-gray-200 dark:border-slate-700 shadow-sm dark:shadow-none">
                <div class="flex items-center gap-2 text-indigo-600 dark:text-indigo-400 font-medium italic animate-pulse">
                  <.icon name="hero-arrow-path" class="w-5 h-5 animate-spin" /> {gettext(
                    "Thinking..."
                  )}
                </div>
              </div>
            </div>
          <% end %>
          
          <%= if @ai_awaiting_approval and not @loading do %>
            <div class="flex justify-start w-full mt-4">
              <div class="ml-4 p-4 rounded-xl border-2 border-indigo-100 dark:border-indigo-900/50 bg-indigo-50/50 dark:bg-slate-800/50 flex flex-col gap-3">
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  {gettext("Are you happy with this implementation plan?")}
                </span>
                <div class="flex items-center gap-2">
                  <button
                    phx-click="approve_plan"
                    class="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg shadow-sm hover:bg-indigo-700 transition"
                  >
                    {gettext("Yes, Build This Flow")}
                  </button>
                  <span class="text-xs text-gray-400 px-2">
                    {gettext("Or reply below with adjustments")}
                  </span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      
      <div class="p-4 bg-white dark:bg-slate-900 border-t border-gray-200 dark:border-slate-800 flex-shrink-0">
        <form phx-submit="send_message" class="max-w-4xl mx-auto flex gap-3 relative items-center">
          <textarea
            name="content"
            id="ai-flow-input"
            phx-hook="FocusInput"
            class="flex-1 w-full bg-slate-50 dark:bg-slate-800 border border-gray-300 dark:border-slate-700 rounded-xl px-5 py-3 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition shadow-sm resize-none"
            placeholder={gettext("Type your prompt here...")}
            autocomplete="off"
            phx-mounted={JS.focus()}
            disabled={@loading}
            autofocus
            rows="3"
            onkeydown="if(event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); this.form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true})); }"
          ></textarea>
          <button
            type="submit"
            disabled={@loading}
            class="p-3 bg-indigo-600 text-white rounded-xl shadow-sm hover:bg-indigo-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center w-[46px] h-[46px] flex-shrink-0"
            title={gettext("Send")}
          >
            <%= if @loading do %>
              <.icon name="hero-arrow-path" class="w-5 h-5 animate-spin" />
            <% else %>
              <.icon name="hero-chevron-right" class="w-6 h-6 stroke-2" />
            <% end %>
          </button>
        </form>
      </div>
    </div>
    """
  end
end
