defmodule FusionFlowWeb.Components.Modals.ExecutionResultModal do
  use FusionFlowWeb, :html

  attr :show_result_modal, :boolean, required: true
  attr :execution_result, :map, default: nil
  attr :inspecting_result, :boolean, default: false

  def execution_result_modal(assigns) do
    ~H"""
    <%= if @show_result_modal do %>
      <div class="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 backdrop-blur-sm">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-xl w-3/4 max-w-2xl max-h-[80vh] flex flex-col border border-gray-200 dark:border-slate-700 animate-in fade-in zoom-in duration-200">
          <div class="flex items-center justify-between p-4 border-b border-gray-200 dark:border-slate-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Execution Output</h3>

            <.button
              variant="ghost"
              phx-click="close_result_modal"
              class="p-1"
            >
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </.button>
          </div>

          <div class="p-6 overflow-y-auto max-h-[60vh] bg-white dark:bg-slate-900">
            <%= if @execution_result && map_size(@execution_result) > 0 do %>
              <%= if @inspecting_result do %>
                <div class="space-y-4 text-left">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-xs font-bold text-indigo-500 uppercase tracking-widest">
                      Full Context JSON
                    </span>
                    <.button
                      phx-click="toggle_inspect_result"
                      variant="ghost"
                      class="text-xs h-auto py-1"
                    >
                      &larr; {gettext("Back to Result")}
                    </.button>
                  </div>
                   <pre class="text-xs font-mono p-4 bg-gray-50 dark:bg-slate-950 rounded-lg border border-gray-200 dark:border-slate-800 text-gray-800 dark:text-slate-300 overflow-x-auto">{Jason.encode!(@execution_result, pretty: true)}</pre>
                </div>
              <% else %>
                <div class="flex flex-col text-left">
                  <div class="mb-4">
                    <span class="text-xs font-bold text-gray-400 dark:text-slate-500 uppercase tracking-[0.2em] block mb-2">
                      Output
                    </span>
                    <div class="text-xl font-mono text-gray-900 dark:text-slate-100 break-words line-clamp-10 selection:bg-indigo-100 dark:selection:bg-indigo-900">
                      <% # Try result, then fallback to status as the user manually changed to that
                      output_val =
                        Map.get(@execution_result, "result") || Map.get(@execution_result, "status") %>
                      <%= if is_nil(output_val) do %>
                        <span class="italic text-gray-400 dark:text-slate-600 font-sans text-base">
                          No output produced
                        </span>
                      <% else %>
                        <%= if is_binary(output_val) do %>
                          {output_val}
                        <% else %>
                          {inspect(output_val, pretty: true)}
                        <% end %>
                      <% end %>
                    </div>
                  </div>

                  <div class="mt-4">
                    <.button
                      phx-click="toggle_inspect_result"
                      variant="ghost"
                      class="flex items-center gap-2 text-sm font-medium text-gray-400 hover:text-indigo-600 dark:text-slate-500 dark:hover:text-indigo-400 transition-all group p-1"
                    >
                      <.icon name="hero-magnifying-glass-plus" class="w-4 h-4 opacity-50 group-hover:opacity-100" />
                      <span class="group-hover:translate-x-1 transition-transform">
                        {gettext("Inspect Full Context")}
                      </span>
                    </.button>
                  </div>
                </div>
              <% end %>
            <% else %>
              <div class="text-left py-4">
                <h3 class="text-base font-medium text-gray-900 dark:text-slate-200">No data</h3>

                <p class="mt-1 text-sm text-gray-500 dark:text-slate-400">
                  The flow finished without any context data.
                </p>
              </div>
            <% end %>
          </div>

          <div class="p-4 border-t border-gray-200 dark:border-slate-700 flex justify-end">
            <.button
              phx-click="close_result_modal"
              variant="primary"
              class="px-6"
            >
              {gettext("Done")}
            </.button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
