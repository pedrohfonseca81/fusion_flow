defmodule FusionFlowWeb.Components.Modals.NodeConfigModal do
  use FusionFlowWeb, :html

  attr :config_modal_open, :boolean, required: true
  attr :editing_node_data, :map, default: nil

  def node_config_modal(assigns) do
    ~H"""
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
                      <% "variable-select" -> %>
                        <select
                          name={key}
                          class="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 dark:bg-slate-900 dark:text-white transition-all h-10"
                        >
                          <option value="">Select a variable...</option>
                          
                          <%= for var <- (@editing_node_data["variables"] || []) do %>
                            <option value={var} selected={var == control["value"]}>{var}</option>
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
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
    """
  end
end
