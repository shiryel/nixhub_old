defmodule CoreWeb.PageController do
  use CoreWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  # def search(conn, _params) do
  #  render(conn, :search, layout: {CoreWeb.Layouts, "app"})
  # end
end
