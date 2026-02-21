defmodule FusionFlowWeb.Components.Modals.DependenciesModal do
  use FusionFlowWeb, :html

  attr :dependencies_modal_open, :boolean, required: true
  attr :dependencies_tab, :string, required: true
  attr :pending_restart_deps, :list, required: true
  attr :search_query, :string, required: true
  attr :search_results, :list, required: true
  attr :installed_deps, :list, required: true
  attr :installing_dep, :string, default: nil
  attr :terminal_logs, :list, required: true

  def dependencies_modal(assigns) do
    ~H"""
    <%= if @dependencies_modal_open do %>
      <div class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm">
        <div class="bg-white dark:bg-slate-900 rounded-lg shadow-2xl w-full max-w-4xl flex flex-col max-h-[90vh] border border-transparent dark:border-slate-800">
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-slate-800">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Project Dependencies
            </h3>
            
            <.button variant="ghost" phx-click="close_dependencies_modal" class="p-1">
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </.button>
          </div>
          
          <div class="flex border-b border-gray-200 dark:border-slate-800 px-6 pt-2">
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
                    <.icon
                      name="hero-magnifying-glass"
                      class="w-5 h-5 text-gray-400 absolute left-3 top-3.5 z-10"
                    />
                    <.input
                      type="text"
                      name="query"
                      value={@search_query}
                      placeholder="Search packages on Hex.pm..."
                      class="pl-10"
                      phx-debounce="500"
                    />
                  </form>
                </div>
                
                <%= if @search_results != [] do %>
                  <div>
                    <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                      Search Results
                    </h4>
                    
                    <div class="grid grid-cols-1 gap-3">
                      <%= for pkg <- @search_results do %>
                        <div class="flex items-center justify-between p-3 border border-gray-200 dark:border-slate-800 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-800/50">
                          <div>
                            <div class="flex items-center gap-2">
                              <span class="font-bold text-gray-900 dark:text-white">{pkg.name}</span>
                              <span class="text-xs bg-indigo-100 text-indigo-800 px-2 py-0.5 rounded-full">
                                {pkg.latest_version}
                              </span>
                            </div>
                            
                            <p class="text-sm text-gray-500 mt-1 line-clamp-1">{pkg.description}</p>
                          </div>
                          
                          <%= if pkg.name in @pending_restart_deps do %>
                            <.button
                              disabled
                              variant="ghost"
                              class="px-3 py-1.5 text-xs bg-yellow-500 text-white rounded cursor-not-allowed opacity-80"
                            >
                              {gettext("Restart Required")}
                            </.button>
                          <% else %>
                            <.button
                              phx-click="install_dependency"
                              phx-value-name={pkg.name}
                              phx-value-version={pkg.latest_version}
                              variant="primary"
                              class="px-3 py-1.5 text-xs"
                            >
                              {gettext("Install")}
                            </.button>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
                
                <%= if @installing_dep do %>
                  <div class="border border-gray-200 dark:border-slate-800 rounded-lg overflow-hidden flex flex-col mt-4">
                    <div class="px-4 py-3 bg-gray-50 dark:bg-slate-800/80 border-b border-gray-200 dark:border-slate-800 flex items-center gap-2">
                      <svg
                        class="animate-spin h-4 w-4 text-indigo-500"
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
                        />
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                        />
                      </svg>
                      <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Installing {@installing_dep}...
                      </span>
                    </div>
                    
                    <div class="bg-black p-4 h-40 overflow-y-auto font-mono text-xs text-green-400">
                      <%= for log <- @terminal_logs do %>
                        <div>{log}</div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
                
                <div>
                  <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                    Installed in mix.exs
                  </h4>
                  
                  <div class="border rounded-lg overflow-hidden border-gray-200 dark:border-slate-800 mt-2">
                    <table class="min-w-full divide-y divide-gray-200 dark:divide-slate-800">
                      <thead class="bg-gray-50 dark:bg-slate-800/50">
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
                      
                      <tbody class="bg-white dark:bg-slate-900 divide-y divide-gray-200 dark:divide-slate-800">
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
                  />
                </svg>
                <p>Support for {@dependencies_tab} dependencies coming soon.</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
