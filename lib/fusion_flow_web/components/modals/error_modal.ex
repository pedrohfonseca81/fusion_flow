defmodule FusionFlowWeb.Components.Modals.ErrorModal do
  use FusionFlowWeb, :html

  attr :error_modal_open, :boolean, required: true
  attr :current_error_node_id, :string, default: nil
  attr :current_error_message, :string, default: nil

  def error_modal(assigns) do
    ~H"""
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

            <.button
              variant="ghost"
              phx-click="close_error_modal"
              class="p-1 !text-red-400 hover:!text-red-600 dark:hover:!text-red-300"
            >
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </.button>
          </div>

          <div class="p-6 overflow-y-auto">
            <div class="mb-4">
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Node ID:</p>

              <code class="px-2 py-1 bg-gray-100 dark:bg-slate-900 rounded text-sm text-gray-700 dark:text-gray-300 font-mono">
                {@current_error_node_id}
              </code>
            </div>

            <div>
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Error Message:</p>

              <div class="p-4 bg-gray-50 dark:bg-slate-900/50 rounded-lg border border-gray-200 dark:border-slate-700 overflow-x-auto">
                <pre class="text-sm text-red-600 dark:text-red-400 font-mono whitespace-pre-wrap">{@current_error_message}</pre>
              </div>
            </div>
          </div>

          <div class="px-6 py-4 border-t border-gray-200 dark:border-slate-700 flex justify-end">
            <.button
              phx-click="close_error_modal"
              variant="danger"
            >
              {gettext("Close")}
            </.button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
