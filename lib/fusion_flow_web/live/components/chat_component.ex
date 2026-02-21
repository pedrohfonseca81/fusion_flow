defmodule FusionFlowWeb.Components.ChatComponent do
  use FusionFlowWeb, :live_component

  attr :open, :boolean, default: false
  attr :messages, :list, default: []
  attr :loading, :boolean, default: false
  attr :ai_configured, :boolean, default: true
  attr :on_toggle, :string, default: "toggle_chat"
  attr :on_send, :string, default: "send_message"

  def render(assigns) do
    ~H"""
    <div>
      <%= unless @open do %>
        <button
          phx-click={JS.push(@on_toggle) |> JS.focus(to: "#chat-input-field")}
          class="fixed bottom-6 right-6 z-[100] p-4 bg-indigo-600 text-white rounded-full shadow-lg hover:bg-indigo-700 transition-all duration-300 flex items-center justify-center group"
          title="AI Chat"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 group-hover:scale-110 transition-transform"
            viewBox="0 0 24 24"
            fill="currentColor"
          >
            <path d="M12 2a2 2 0 012 2c0 .74-.4 1.39-1 1.73V7h1a7 7 0 017 7h1a1 1 0 011 1v3a1 1 0 01-1 1h-1v1a2 2 0 01-2 2H5a2 2 0 01-2-2v-1H2a1 1 0 01-1-1v-3a1 1 0 011-1h1a7 7 0 017-7h1V5.73c-.6-.34-1-.99-1-1.73a2 2 0 012-2zM9 11a2 2 0 100 4 2 2 0 000-4zm6 0a2 2 0 100 4 2 2 0 000-4z" />
          </svg>
        </button>
      <% end %>
      
      <div class={"fixed top-0 right-0 h-full w-[350px] bg-white dark:bg-slate-900 shadow-2xl z-[100] transform transition-transform duration-300 ease-in-out flex flex-col border-l border-gray-200 dark:border-slate-800 " <> if(@open, do: "translate-x-0", else: "translate-x-full")}>
        <div class="p-4 border-b border-gray-200 dark:border-slate-800 flex items-center justify-between bg-gray-50 dark:bg-slate-800">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M12 2a2 2 0 012 2c0 .74-.4 1.39-1 1.73V7h1a7 7 0 017 7h1a1 1 0 011 1v3a1 1 0 01-1 1h-1v1a2 2 0 01-2 2H5a2 2 0 01-2-2v-1H2a1 1 0 01-1-1v-3a1 1 0 011-1h1a7 7 0 017-7h1V5.73c-.6-.34-1-.99-1-1.73a2 2 0 012-2zM9 11a2 2 0 100 4 2 2 0 000-4zm6 0a2 2 0 100 4 2 2 0 000-4z" />
              </svg>
            </div>
             <span class="font-semibold text-gray-900 dark:text-white">AI Assistant</span>
          </div>
          
          <button
            phx-click={@on_toggle}
            class="text-gray-500 hover:text-gray-700 dark:text-slate-400 dark:hover:text-slate-200"
            title="Close Chat"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-4 space-y-4" id="chat-messages" phx-hook="ScrollToBottom">
          <%= for {role, content} <- @messages, not (role == :ai and content == "") do %>
            <div class={"flex " <> if(role == :user, do: "justify-end", else: "justify-start")}>
              <div class={"max-w-[85%] rounded-2xl px-4 py-3 text-sm " <>
                if(role == :user,
                  do: "bg-indigo-600 text-white rounded-br-none shadow-sm dark:shadow-none",
                  else: "bg-gray-100 dark:bg-slate-800 text-gray-800 dark:text-gray-200 rounded-bl-none border border-gray-200 dark:border-slate-700 shadow-sm dark:shadow-none")}>
                <%= if String.contains?(content, "\"action\": \"create_flow\"") or String.starts_with?(String.trim(content), "{") do %>
                  <div class="flex items-center gap-2 text-indigo-600 dark:text-indigo-400 font-medium italic animate-pulse">
                    <svg
                      class="animate-spin h-4 w-4"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    Constructing flow...
                  </div>
                <% else %>
                  {content}
                <% end %>
              </div>
            </div>
          <% end %>
          
          <%= if @loading and (List.last(@messages) |> elem(1)) == "" do %>
            <div class="flex justify-start">
              <div class="max-w-[85%] rounded-2xl px-4 py-3 text-sm bg-gray-100 dark:bg-slate-800 text-gray-800 dark:text-gray-200 rounded-bl-none border border-gray-200 dark:border-slate-700 shadow-sm dark:shadow-none">
                <div class="flex items-center gap-2 text-indigo-600 dark:text-indigo-400 font-medium italic animate-pulse">
                  <svg
                    class="animate-spin h-4 w-4"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                  Thinking...
                </div>
              </div>
            </div>
          <% end %>
          
          <%= if not @ai_configured do %>
            <div class="flex flex-col items-center justify-center h-full text-gray-400 dark:text-gray-500 px-6">
              <div class="w-16 h-16 bg-amber-100 dark:bg-amber-900/30 rounded-2xl flex items-center justify-center mb-4">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="w-8 h-8 text-amber-600 dark:text-amber-400"
                >
                  <path
                    fill-rule="evenodd"
                    d="M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003zM12 8.25a.75.75 0 01.75.75v3.75a.75.75 0 01-1.5 0V9a.75.75 0 01.75-.75zm0 8.25a.75.75 0 100-1.5.75.75 0 000 1.5z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              
              <p class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
                AI Assistant Disabled
              </p>
              
              <p class="text-xs text-center text-gray-500 dark:text-gray-400">
                Set
                <code class="bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded font-mono text-xs">
                  OPENAI_API_KEY
                </code>
                in your environment to enable the chat.
              </p>
            </div>
          <% else %>
            <%= if Enum.empty?(@messages) do %>
              <div class="flex flex-col items-center justify-center h-full text-gray-400 dark:text-gray-500 text-sm italic">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-12 w-12 mb-2 opacity-50"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                  />
                </svg>
                <p>How can I help you with your flow?</p>
              </div>
            <% end %>
          <% end %>
        </div>
        
        <%= if @ai_configured do %>
          <div class="p-4 border-t border-gray-200 dark:border-slate-800 bg-white dark:bg-slate-900">
            <form phx-submit={@on_send} class="flex gap-2 items-center">
              <textarea
                name="content"
                id="chat-input-field"
                placeholder={if @loading, do: "AI is thinking...", else: "Message AI..."}
                disabled={@loading}
                onkeydown="if(event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); this.form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true})); }"
                class={[
                  "flex-1 w-full pl-4 pr-4 py-3 rounded-xl border border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all placeholder-gray-400 dark:placeholder-gray-500 text-sm shadow-sm dark:shadow-none resize-none",
                  if(@loading, do: "cursor-not-allowed opacity-60")
                ]}
                rows="3"
              ></textarea>
              <button
                type="submit"
                disabled={@loading}
                title={gettext("Send")}
                class={[
                  "p-2.5 bg-indigo-600 text-white rounded-xl shadow-sm hover:bg-indigo-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center w-[42px] h-[42px] flex-shrink-0",
                  if(@loading, do: "cursor-not-allowed opacity-50")
                ]}
              >
                <%= if @loading do %>
                  <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" />
                <% else %>
                  <.icon name="hero-chevron-right" class="w-5 h-5 stroke-2" />
                <% end %>
              </button>
            </form>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
