defmodule FusionFlowWeb.UserLive.Login do
  use FusionFlowWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[80vh] flex flex-col items-center justify-center p-4">
      <div class="w-full max-w-md bg-white dark:bg-slate-800 p-8 rounded-3xl shadow-2xl border border-gray-100 dark:border-slate-700/50">
        <div class="text-center mb-8">
          <h1 class="text-3xl font-extrabold text-gray-900 dark:text-white tracking-tight">
            {gettext("Welcome back")}
          </h1>
          
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            <%= if @current_scope && @current_scope.user do %>
              {gettext("You need to re-authenticate to perform sensitive actions.")}
            <% else %>
              {gettext("Sign in to your account to continue")}
            <% end %>
          </p>
        </div>
        
        <div
          :if={local_mail_adapter?()}
          class="mb-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-100 dark:border-blue-800 flex gap-3"
        >
          <.icon
            name="hero-information-circle"
            class="size-5 text-blue-600 dark:text-blue-400 shrink-0"
          />
          <div class="text-xs text-blue-700 dark:text-blue-300">
            <p class="font-bold">Local Mail Adapter active</p>
            
            <p class="mt-1">
              Sent emails are available at <.link href="/dev/mailbox" class="font-bold underline">/dev/mailbox</.link>.
            </p>
          </div>
        </div>
        
        <.form
          :let={f}
          for={@form}
          id="login_form"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
          class="space-y-5"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:username]}
            type="text"
            label={gettext("Username")}
            placeholder={gettext("Enter your username")}
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={f[:password]}
            type="password"
            label={gettext("Password")}
            placeholder="••••••••"
            required
          />
          <div class="pt-2">
            <.button
              variant="primary"
              class="w-full py-4 text-base font-bold shadow-lg shadow-indigo-500/25 transition-all hover:shadow-indigo-500/40 active:scale-[0.98]"
              name={f[:remember_me].name}
              value="true"
            >
              {gettext("Log in")}
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    username =
      Phoenix.Flash.get(socket.assigns.flash, :username) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:username)])

    form = to_form(%{"username" => username}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  defp local_mail_adapter? do
    Application.get_env(:fusion_flow, FusionFlow.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
