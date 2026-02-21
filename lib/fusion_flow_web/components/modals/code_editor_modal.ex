defmodule FusionFlowWeb.Components.Modals.CodeEditorModal do
  use FusionFlowWeb, :html

  attr :modal_open, :boolean, required: true
  attr :current_code_tab, :string, required: true
  attr :current_code_elixir, :string, required: true
  attr :current_code_python, :string, required: true
  attr :available_variables, :list, required: true

  def code_editor_modal(assigns) do
    ~H"""
    <%= if @modal_open do %>
      <div class="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm">
        <div class="bg-white dark:bg-slate-800 rounded-lg shadow-2xl w-full max-w-4xl flex flex-col h-[80vh] border border-gray-200 dark:border-slate-700 animate-in fade-in zoom-in duration-200">
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-slate-100 flex items-center gap-2">
              <span class="p-1 rounded bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                  />
                </svg>
              </span>
              Edit Code
            </h3>
            
            <.button
              variant="ghost"
              phx-click="close_modal"
              class="p-1"
            >
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </.button>
          </div>
          
          <div class="flex border-b border-gray-200 dark:border-slate-700 px-6 bg-gray-50 dark:bg-slate-800/50">
            <button
              type="button"
              phx-click="switch_code_tab"
              phx-value-tab="elixir"
              class={"px-4 py-3 text-sm font-medium border-b-2 -mb-px #{if @current_code_tab == "elixir", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
            >
              <span class="flex items-center gap-2">
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2C8.5 6 6 10 6 14.5C6 18.09 8.69 21 12 21C15.31 21 18 18.09 18 14.5C18 10 15.5 6 12 2Z" />
                </svg>
                Elixir
              </span>
            </button>
            <button
              type="button"
              phx-click="switch_code_tab"
              phx-value-tab="python"
              class={"px-4 py-3 text-sm font-medium border-b-2 -mb-px #{if @current_code_tab == "python", do: "border-indigo-500 text-indigo-600 dark:text-indigo-400", else: "border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"}"}
            >
              <span class="flex items-center gap-2">
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
                </svg>
                Python
              </span>
            </button>
          </div>
          
          <form phx-submit="save_code" class="flex-1 flex flex-col overflow-hidden">
            <div
              class="flex-1 p-0 overflow-hidden relative bg-[#1e1e1e]"
              id="code-editor-wrapper"
              phx-update="ignore"
              phx-hook="CodeEditor"
              data-variables={Jason.encode!(@available_variables)}
              data-language={@current_code_tab}
            >
              <textarea id="code_elixir_textarea" name="code_elixir" class="w-full h-full hidden"><%= @current_code_elixir %></textarea> <textarea
                id="code_python_textarea"
                name="code_python"
                class="w-full h-full hidden"
              ><%= @current_code_python %></textarea>
            </div>
            
            <div class="px-6 py-4 bg-white dark:bg-slate-800 border-t border-gray-200 dark:border-slate-700 flex justify-end gap-3 rounded-b-lg">
              <.button
                type="button"
                variant="outline"
                phx-click="close_modal"
              >
                {gettext("Cancel")}
              </.button>
              <.button
                type="submit"
                variant="success"
              >
                <.icon name="hero-check" class="w-4 h-4 mr-1" /> {gettext("Save Changes")}
              </.button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end
end
