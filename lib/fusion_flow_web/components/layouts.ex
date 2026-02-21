defmodule FusionFlowWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FusionFlowWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :locale, :string, default: nil

  slot :inner_block, required: false

  def app(assigns) do
    assigns = assign_new(assigns, :locale, fn -> Gettext.get_locale(FusionFlowWeb.Gettext) end)

    ~H"""
    <div class="flex h-screen w-full bg-gray-50 dark:bg-slate-950 overflow-hidden">
      <%= if @current_scope && @current_scope.user do %>
        <aside class="w-20 lg:w-64 bg-white dark:bg-slate-900 border-r border-gray-200 dark:border-slate-800 flex flex-col items-center lg:items-start py-6 shadow-sm z-20 transition-all duration-300">
          <div class="px-0 lg:px-6 w-full flex justify-center lg:justify-start mb-8">
            <.link
              navigate={~p"/"}
              class="flex items-center gap-2 group transition-opacity hover:opacity-80"
            >
              <div class="p-2 lg:p-1.5 w-10 h-10 lg:w-8 lg:h-8 rounded-lg bg-gradient-to-br from-indigo-600 to-purple-600 flex items-center justify-center shadow-sm">
                <svg
                  class="w-6 h-6 lg:w-5 lg:h-5 text-white shadow-sm"
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
              <span class="hidden lg:block text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-gray-900 to-gray-600 dark:from-white dark:to-gray-400 tracking-tight">
                FusionFlow
              </span>
            </.link>
          </div>

          <nav class="flex-1 w-full px-3 lg:px-4 space-y-2">
            <.link
              navigate={~p"/"}
              class="flex items-center justify-center lg:justify-start gap-3 px-3 py-2.5 rounded-lg text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-800 hover:text-gray-900 dark:hover:text-white transition-all group"
            >
              <svg
                class="w-6 h-6 lg:w-5 lg:h-5 text-gray-500 dark:text-gray-500 group-hover:text-indigo-600 dark:group-hover:text-indigo-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                />
              </svg>
              <span class="hidden lg:block font-medium text-sm">{gettext("Dashboard")}</span>
            </.link>

            <.link
              navigate={~p"/flows"}
              class="flex items-center justify-center lg:justify-start gap-3 px-3 py-2.5 rounded-lg text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-800 hover:text-gray-900 dark:hover:text-white transition-all group"
            >
              <svg
                class="w-6 h-6 lg:w-5 lg:h-5 text-gray-500 dark:text-gray-500 group-hover:text-indigo-600 dark:group-hover:text-indigo-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
                />
              </svg>
              <span class="hidden lg:block font-medium text-sm">{gettext("My Flows")}</span>
            </.link>

            <.link
              navigate={~p"/flows/new/ai"}
              class="flex items-center justify-center lg:justify-start gap-3 px-3 py-2.5 rounded-lg text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-800 hover:text-gray-900 dark:hover:text-white transition-all group"
            >
              <svg
                class="w-6 h-6 lg:w-5 lg:h-5 text-gray-500 dark:text-gray-500 group-hover:text-purple-600 dark:group-hover:text-purple-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                />
              </svg>
              <span class="hidden lg:block font-medium text-sm">{gettext("Create with AI")}</span>
            </.link>
          </nav>

          <div class="px-3 lg:px-4 w-full mt-auto">
            <div class="hidden lg:block w-full text-xs text-gray-500 dark:text-gray-500 px-2 mt-4">
              <form id="locale-form" phx-change="change_locale" class="w-full">
                <label for="locale-select" class="sr-only">Language</label>
                <select
                  id="locale-select"
                  name="locale"
                  class="w-full bg-slate-100 dark:bg-slate-800 border-none rounded-md text-gray-600 dark:text-gray-400 py-1.5 px-2 text-xs focus:ring-1 focus:ring-indigo-500"
                  onchange="window.location.href = '?locale=' + this.value"
                >
                  <option value="en" selected={@locale == "en"}>English</option>
                  <option value="pt_BR" selected={@locale == "pt_BR"}>Português (BR)</option>
                </select>
              </form>
            </div>

            <div class="hidden lg:flex w-full mt-4 justify-between items-center text-xs text-gray-500 dark:text-gray-500 px-2">
              <span>{gettext("Theme")}</span>
              <.theme_toggle />
            </div>

            <div class="mt-6 pt-6 border-t border-gray-100 dark:border-slate-800">
              <div class="relative group" id="user-menu-root">
                <.button
                  id="user-menu-button"
                  variant="ghost"
                  phx-click={JS.toggle(to: "#user-menu-dropdown", in: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"}, out: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"})}
                  class="w-full !justify-start p-2 rounded-xl"
                >
                  <div class="flex items-center w-full">
                    <div class="flex-shrink-0">
                      <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm shadow-sm">
                        {String.at(@current_scope.user.username || @current_scope.user.email, 0) |> String.upcase()}
                      </div>
                    </div>
                    <div class="hidden lg:block ml-3 text-left overflow-hidden">
                      <p class="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {@current_scope.user.username || "User"}
                      </p>
                      <p class="text-xs text-gray-500 dark:text-gray-400 truncate">
                        {@current_scope.user.email}
                      </p>
                    </div>
                    <div class="hidden lg:block ml-auto">
                      <.icon name="hero-chevron-down-mini" class="size-4 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300 transition-colors" />
                    </div>
                  </div>
                </.button>

                <div
                  id="user-menu-dropdown"
                  class="absolute bottom-full left-0 mb-2 w-full bg-white dark:bg-slate-900 rounded-xl shadow-xl border border-gray-100 dark:border-slate-800 overflow-hidden z-50 hidden"
                  phx-click-away={JS.hide(to: "#user-menu-dropdown")}
                >
                  <div class="p-2 space-y-1">
                    <.link
                      navigate={~p"/users/settings"}
                      class="flex items-center gap-3 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-800 rounded-lg transition-colors"
                    >
                      <.icon name="hero-cog-6-tooth" class="size-4" />
                      {gettext("Settings")}
                    </.link>

                    <.link
                      href={~p"/users/log-out"}
                      method="delete"
                      class="flex items-center gap-3 px-3 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/10 rounded-lg transition-colors"
                    >
                      <.icon name="hero-arrow-right-on-rectangle" class="size-4" />
                      {gettext("Log out")}
                    </.link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </aside>
      <% end %>

      <main class="flex-1 overflow-auto relative flex flex-col">
        <%= if Map.has_key?(assigns, :inner_content) do %>
          {@inner_content}
        <% else %>
          {render_slot(assigns[:inner_block])}
        <% end %>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
