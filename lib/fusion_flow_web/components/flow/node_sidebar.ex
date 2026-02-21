defmodule FusionFlowWeb.Components.Flow.NodeSidebar do
  use FusionFlowWeb, :html

  attr :nodes_by_category, :map, required: true

  def node_sidebar(assigns) do
    ~H"""
    <aside class="w-64 bg-gray-50 dark:bg-slate-800 border-r border-gray-200 dark:border-slate-700 flex flex-col z-10 shadow-lg dark:shadow-black/20">
      <div class="p-4 border-b border-gray-200 dark:border-slate-700">
        <h2 class="text-sm font-semibold text-gray-500 dark:text-slate-400 uppercase tracking-wider">
          Nodes
        </h2>
      </div>
      
      <div class="flex-1 overflow-y-auto pt-4 pb-4 space-y-6">
        <%= for {category, nodes} <- @nodes_by_category do %>
          <% {label, color_class} = category_meta(category) %>
          <div>
            <h3 class="text-xs font-semibold text-gray-400 dark:text-slate-500 uppercase tracking-wider mb-2 px-4">
              {label}
            </h3>
            
            <div class="space-y-0.5">
              <%= for node <- nodes do %>
                <% is_active =
                  node.name in [
                    "Evaluate Code",
                    "Start",
                    "Output",
                    "Logger",
                    "Variable",
                    "HTTP Request",
                    "Condition"
                  ] %>
                <button
                  draggable={is_active |> to_string()}
                  data-node-name={node.name}
                  phx-click={if is_active, do: "show_drag_tooltip", else: nil}
                  phx-value-name={node.name}
                  disabled={!is_active}
                  title={if is_active, do: "Drag and drop onto the canvas to add", else: nil}
                  class={[
                    "w-full flex items-center justify-between gap-3 px-4 py-2 text-sm font-medium transition-colors",
                    if(is_active,
                      do:
                        "text-gray-700 dark:text-slate-300 bg-transparent hover:bg-gray-100 dark:hover:bg-slate-700/50 focus:outline-none focus:bg-gray-100 dark:focus:bg-slate-700/50 cursor-grab active:cursor-grabbing",
                      else: "text-gray-400 dark:text-slate-600 bg-transparent cursor-not-allowed"
                    )
                  ]}
                >
                  <div class="flex items-center gap-3">
                    <span class={[
                      "w-5 h-5 rounded flex items-center justify-center text-xs",
                      if(is_active,
                        do: color_class,
                        else: "bg-gray-100 text-gray-400 dark:bg-slate-800 dark:text-slate-600"
                      )
                    ]}>
                      {node.icon}
                    </span> {node.name}
                  </div>
                  
                  <%= if not is_active do %>
                    <span class="text-[10px] uppercase font-bold text-gray-400 dark:text-slate-600 tracking-wider">
                      Coming Soon
                    </span>
                  <% end %>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </aside>
    """
  end

  defp category_meta(:trigger), do: {"Triggers", "bg-green-100 text-green-600"}
  defp category_meta(:flow_control), do: {"Flow Control", "bg-yellow-100 text-yellow-600"}
  defp category_meta(:code), do: {"Code", "bg-indigo-100 text-indigo-700"}
  defp category_meta(:integration), do: {"Integration", "bg-orange-100 text-orange-600"}
  defp category_meta(:data_manipulation), do: {"Data", "bg-blue-100 text-blue-600"}
  defp category_meta(:utility), do: {"Utility", "bg-gray-100 text-gray-600"}
  defp category_meta(_), do: {"Other", "bg-gray-100 text-gray-600"}
end
