defmodule FusionFlowWeb.FlowListLive do
  use FusionFlowWeb, :live_view

  alias FusionFlow.Flows

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, flows: Flows.list_flows(), page_title: gettext("My Flows"))}
  end

  @impl true
  def handle_event("create_flow", _params, socket) do
    case Flows.create_flow(%{
           name: "New Flow #{System.unique_integer([:positive])}",
           nodes: [],
           connections: []
         }) do
      {:ok, flow} ->
        {:noreply, push_navigate(socket, to: ~p"/flows/#{flow}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create flow."))}
    end
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
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{gettext("My Flows")}</h1>

          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {length(@flows)} {gettext("Flows available")}
          </p>
        </div>

        <.button
          phx-click="create_flow"
          variant="primary"
        >
          <.icon name="hero-plus" class="h-4 w-4 mr-1" />
          {gettext("New Flow")}
        </.button>
      </div>

      <div>
        <%= if Enum.empty?(@flows) do %>
          <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl p-12 text-center shadow-sm">
            <div class="mx-auto w-16 h-16 bg-gray-100 dark:bg-slate-700 rounded-full flex items-center justify-center mb-4">
              <svg
                class="w-8 h-8 text-gray-400 dark:text-gray-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
            </div>

            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-1">
              {gettext("No flows created yet")}
            </h3>

            <p class="text-gray-500 dark:text-gray-400 mb-6 max-w-sm mx-auto text-center">
              {gettext("Get started by creating your first workflow automation. It's easy!")}
            </p>

            <.button
              phx-click="create_flow"
              variant="primary"
              class="px-6 py-3"
            >
              <.icon name="hero-plus" class="h-5 w-5 mr-1" />
              {gettext("Create your first flow")}
            </.button>
          </div>
        <% else %>
          <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden">
            <ul role="list" class="divide-y divide-gray-200 dark:divide-slate-700">
              <%= for flow <- @flows do %>
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
                          {length(flow.nodes || [])} {gettext("nodes")} • {length(
                            flow.connections || []
                          )} {gettext("connections")} • {gettext("Updated")} {Calendar.strftime(
                            flow.updated_at,
                            "%b %d, %Y"
                          )}
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
