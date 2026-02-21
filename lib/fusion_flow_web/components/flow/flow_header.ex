defmodule FusionFlowWeb.Components.Flow.FlowHeader do
  use FusionFlowWeb, :html

  attr :has_changes, :boolean, required: true
  attr :flow, :any, required: true
  attr :renaming_flow, :boolean, default: false

  def flow_header(assigns) do
    ~H"""
    <header class="flex items-center justify-between px-6 py-3 border-b border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-800 z-10 h-16 shadow-md dark:shadow-black/50">
      <div class="flex items-center gap-4">
        <.link
          navigate={~p"/"}
          class="flex items-center gap-2 group transition-opacity hover:opacity-80"
        >
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
          
          <span class="text-lg font-bold bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 dark:from-white dark:to-gray-400">
            FusionFlow
          </span>
        </.link>
        <div class="h-8 w-px bg-gray-200 dark:bg-slate-700 hidden sm:block"></div>
        
        <div class="hidden sm:block">
          <%= if @renaming_flow do %>
            <form
              phx-submit="save_flow_name"
              phx-click-away="cancel_rename_flow"
              class="flex items-center gap-2"
            >
              <input
                type="text"
                name="name"
                value={@flow.name}
                id="flow-name-input"
                phx-mounted={JS.focus()}
                class="px-2 py-1 text-sm font-bold text-gray-900 dark:text-white bg-white dark:bg-slate-900 border border-indigo-500 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500/50"
              />
              <button
                type="submit"
                class="p-1 text-green-600 hover:text-green-700 dark:text-green-400 dark:hover:text-green-300"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </button>
            </form>
          <% else %>
            <div class="flex items-center gap-2 group/title">
              <h1 class="text-base font-bold text-gray-900 dark:text-white leading-tight">
                {@flow.name}
              </h1>
              
              <button
                phx-click="edit_flow_name"
                class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 opacity-0 group-hover/title:opacity-100 transition-opacity"
                title="Rename Flow"
              >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                  />
                </svg>
              </button>
            </div>
          <% end %>
          
          <div class="flex items-center gap-1.5 mt-0.5">
            <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            <p class="text-xs text-gray-500 dark:text-gray-400 font-medium">Active Session</p>
          </div>
        </div>
      </div>
      
      <div class="flex items-center gap-3">
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
            />
          </svg> <span class="hidden sm:inline">Dependencies</span>
        </button>
        <button
          phx-click="run_flow"
          class="h-9 px-4 flex items-center gap-2 text-sm font-semibold text-white bg-green-600 hover:bg-green-700 rounded-md transition-colors"
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

    <%= if @has_changes do %>
      <div class="absolute bottom-6 left-1/2 transform -translate-x-1/2 bg-white dark:bg-slate-800 px-6 py-3 rounded-full shadow-lg dark:shadow-black/50 border border-gray-200 dark:border-slate-700 z-50 flex items-center gap-4 animate-bounce-in">
        <span class="text-sm font-medium text-gray-700 dark:text-slate-200">
          You have unsaved changes
        </span>
        <button
          phx-click="save_graph"
          class="px-4 py-1.5 bg-green-600 text-white text-sm font-semibold rounded-full hover:bg-green-700 transition"
        >
          Save Changes
        </button>
      </div>
    <% end %>
    """
  end
end
