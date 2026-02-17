defmodule FusionFlowWeb.Components.ChatComponent do
  use FusionFlowWeb, :live_component

  attr :open, :boolean, default: false
  attr :messages, :list, default: []
  attr :on_toggle, :string, default: "toggle_chat"
  attr :on_send, :string, default: "send_message"

  def render(assigns) do
    ~H"""
    <div>
      <!-- Floating Button -->
      <%= unless @open do %>
        <button
          phx-click={@on_toggle}
          class="fixed bottom-6 right-6 z-50 p-4 bg-indigo-600 text-white rounded-full shadow-lg hover:bg-indigo-700 transition-all duration-300 flex items-center justify-center group"
          title="AI Chat"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6 group-hover:scale-110 transition-transform"
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
        </button>
      <% end %>
      <!-- Sidebar -->
      <div class={"fixed top-0 right-0 h-full w-[20%] bg-white dark:bg-gray-900 shadow-2xl z-40 transform transition-transform duration-300 ease-in-out flex flex-col border-l border-gray-200 dark:border-gray-800 " <> if(@open, do: "translate-x-0", else: "translate-x-full")}>
        <!-- Header -->
        <div class="p-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between bg-gray-50 dark:bg-gray-800/50">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
             <span class="font-semibold text-gray-900 dark:text-white">AI Assistant</span>
          </div>
          
          <button
            phx-click={@on_toggle}
            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
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
        <!-- Messages Area -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4" id="chat-messages" phx-update="append">
          <%= for {role, content} <- @messages do %>
            <div class={"flex " <> if(role == :user, do: "justify-end", else: "justify-start")}>
              <div class={"max-w-[85%] rounded-2xl px-4 py-3 text-sm " <>
                if(role == :user,
                  do: "bg-indigo-600 text-white rounded-br-none",
                  else: "bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-bl-none border border-gray-200 dark:border-gray-700")}>
                {content}
              </div>
            </div>
          <% end %>
          
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
        </div>
        <!-- Input Area -->
        <div class="p-4 border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          <form phx-submit={@on_send} class="relative">
            <input
              type="text"
              name="content"
              placeholder="Message AI..."
              class="w-full pr-12 pl-4 py-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all placeholder-gray-400 dark:placeholder-gray-500 text-sm shadow-sm"
              autocomplete="off"
            />
            <button
              type="submit"
              class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg transition-colors"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
              </svg>
            </button>
          </form>
          <!-- Model Selector -->
          <div class="mt-3 flex justify-center">
            <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-gray-100 dark:bg-gray-800 text-xs text-gray-600 dark:text-gray-400 border border-gray-200 dark:border-gray-700 cursor-pointer hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3 w-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                />
              </svg> <span class="font-medium">Model</span>
              <span class="font-bold text-gray-800 dark:text-gray-200">gpt-5 mini</span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3 w-3 ml-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
