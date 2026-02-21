defmodule FusionFlowWeb.UserLive.Settings do
  use FusionFlowWeb, :live_view

  on_mount {FusionFlowWeb.UserAuth, :require_sudo_mode}

  alias FusionFlow.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 md:p-8 w-full max-w-7xl mx-auto">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
            {gettext("Account Settings")}
          </h1>
          
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {gettext("Manage your account settings, security, and preferences.")}
          </p>
        </div>
      </div>
      
      <div class="space-y-6">
        <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden">
          <div class="p-6 border-b border-gray-100 dark:border-slate-700/50">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white">
              {gettext("Profile Information")}
            </h3>
            
            <p class="text-xs text-gray-500 dark:text-gray-400">
              {gettext("Update your public username and email address.")}
            </p>
          </div>
          
          <div class="p-6 space-y-6">
            <.form
              for={@username_form}
              id="username_form"
              phx-submit="update_username"
              phx-change="validate_username"
              class="space-y-4"
            >
              <.input
                field={@username_form[:username]}
                type="text"
                label={gettext("Username")}
                required
              />
              <div class="flex justify-end">
                <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                  {gettext("Update Username")}
                </.button>
              </div>
            </.form>
            
            <div class="border-t border-gray-100 dark:border-slate-700/50 pt-6">
              <.form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
                class="space-y-4"
              >
                <.input
                  field={@email_form[:email]}
                  type="email"
                  label={gettext("Email Address")}
                  required
                />
                <div class="flex justify-end">
                  <.button variant="primary" phx-disable-with={gettext("Changing...")}>
                    {gettext("Change Email")}
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
        
        <div class="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden">
          <div class="p-6 border-b border-gray-100 dark:border-slate-700/50">
            <h3 class="text-base font-semibold text-gray-900 dark:text-white">
              {gettext("Change Password")}
            </h3>
            
            <p class="text-xs text-gray-500 dark:text-gray-400">
              {gettext("Ensure your account is using a long, random password to stay secure.")}
            </p>
          </div>
          
          <div class="p-6">
            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <.input
                field={@password_form[:password]}
                type="password"
                label={gettext("New Password")}
                autocomplete="new-password"
                required
              />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label={gettext("Confirm New Password")}
                autocomplete="new-password"
              />
              <div class="flex justify-end">
                <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                  {gettext("Update Password")}
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    username_changeset = Accounts.change_user_username(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_username", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_username(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.update_user_username(user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Username updated successfully.")
         |> assign(:username_form, to_form(Accounts.change_user_username(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :username_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.update_user_email_directly(user, user_params) do
      {:ok, user} ->
        info = "Email updated successfully."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(:current_email, user.email)
         |> assign(:email_form, to_form(Accounts.change_user_email(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(changeset))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
