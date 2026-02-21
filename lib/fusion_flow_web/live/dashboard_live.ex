defmodule FusionFlowWeb.DashboardLive do
  use FusionFlowWeb, :live_view

  alias FusionFlow.Flows

  @impl true
  def mount(_params, _session, socket) do
    flows = Flows.list_flows()
    active_count = length(flows)

    {:ok,
     socket
     |> assign(page_title: "Dashboard")
     |> assign(flows: flows)
     |> assign(active_count: active_count)}
  end

  @impl true
  def handle_event("change_locale", %{"locale" => locale}, socket) do
    {:noreply, redirect(socket, to: ~p"/?locale=#{locale}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 md:p-8 w-full max-w-7xl mx-auto">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{gettext("Dashboard")}</h1>
          
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {gettext("Welcome back to FusionFlow! Here's an overview of your automated logic.")}
          </p>
        </div>
        
        <.button
          navigate={~p"/flows"}
          variant="primary"
        >
          {gettext("Manage Flows")}
        </.button>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
              {gettext("Total Workflows")}
            </h3>
            
            <div class="p-2 bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 rounded-lg">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
                />
              </svg>
            </div>
          </div>
           <span class="text-3xl font-bold text-gray-900 dark:text-white">{@active_count}</span>
        </div>
        
        <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
              {gettext("Total Processed Nodes")}
            </h3>
            
            <div class="p-2 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 rounded-lg">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
          </div>
           <span class="text-3xl font-bold text-gray-900 dark:text-white">--</span>
          <p class="text-xs text-gray-400 mt-1 placeholder-text">Coming soon</p>
        </div>
        
        <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-6 shadow-sm">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">
              {gettext("Active Integrations")}
            </h3>
            
            <div class="p-2 bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400 rounded-lg">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
            </div>
          </div>
           <span class="text-3xl font-bold text-gray-900 dark:text-white">--</span>
          <p class="text-xs text-gray-400 mt-1 placeholder-text">Coming soon</p>
        </div>
      </div>
      
      <div>
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          {gettext("Recent Workflows")}
        </h2>
        
        <%= if Enum.empty?(@flows) do %>
          <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-8 text-center shadow-sm">
            <div class="mx-auto w-12 h-12 bg-gray-100 dark:bg-slate-700 rounded-full flex items-center justify-center mb-3">
              <svg class="w-6 h-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
            </div>
            
            <h3 class="text-sm font-medium text-gray-900 dark:text-white">{gettext("No flows")}</h3>
            
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {gettext("Get started by creating a new workflow automation.")}
            </p>
            
            <div class="mt-6">
              <.button
                navigate={~p"/flows"}
                variant="outline"
              >
                {gettext("Create Flow")} &rarr;
              </.button>
            </div>
          </div>
        <% else %>
          <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden">
            <ul role="list" class="divide-y divide-gray-200 dark:divide-slate-700">
              <%= for flow <- Enum.take(@flows, 5) do %>
                <li class="hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors">
                  <.link
                    navigate={~p"/flows/#{flow.id}"}
                    class="flex items-center justify-between px-6 py-4"
                  >
                    <div class="flex items-center gap-4">
                      <div class="p-2 bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 rounded-lg">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 10V3L4 14h7v7l9-11h-7z"
                          />
                        </svg>
                      </div>
                      
                      <div>
                        <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                          {flow.name}
                        </p>
                        
                        <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                          {length(flow.nodes || [])} nodes • {length(flow.connections || [])} connections
                        </p>
                      </div>
                    </div>
                    
                    <div>
                      <svg class="w-5 h-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                        <path
                          fill-rule="evenodd"
                          d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </div>
                  </.link>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
