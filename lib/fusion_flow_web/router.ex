defmodule FusionFlowWeb.Router do
  use FusionFlowWeb, :router

  import FusionFlowWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FusionFlowWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug FusionFlowWeb.Plugs.SetLocale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # JSON API Scope
  scope "/api", FusionFlowWeb do
    pipe_through :api

    resources "/flows", FlowController, except: [:new, :edit]
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:fusion_flow, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FusionFlowWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", FusionFlowWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FusionFlowWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/", DashboardLive
      live "/flows", FlowListLive
      live "/flows/new/ai", FlowAiCreatorLive
      live "/flows/:id", FlowLive
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", FusionFlowWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{FusionFlowWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
