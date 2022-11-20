defmodule CoreWeb.Router do
  use CoreWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  scope "/", CoreWeb do
    pipe_through :browser

    live "/", SearchLive.Index, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CoreWeb do
  #   pipe_through :api
  # end

  if Application.compile_env(:core, :dev_routes) do
    # Enable LiveDashboard and Swoosh mailbox preview in development
    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  else
    scope "/" do
      pipe_through [:browser, :admins_only]
      live_dashboard "/dashboard", metrics: CoreWeb.Telemetry
    end
  end

  defp admin_basic_auth(conn, _opts) do
    username = Application.fetch_env!(:core, :admin_username)
    password = Application.fetch_env!(:core, :admin_password)
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
