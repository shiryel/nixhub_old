defmodule CoreWeb.SearchLive.Index do
  use CoreWeb, :live_view

  import __MODULE__.Components

  alias Core.Nix

  @limit 30
  @page_limit 20

  @impl true
  def mount(_params, _session, socket) do
    default_version = Nix.list_versions() |> List.first()

    %{hits: hits, hit_count: hit_count, time: time} =
      Nix.search_package(%{q: "nix", limit: @limit, filter: []}, "packages", default_version)

    socket =
      socket
      |> assign(%{
        page: 0,
        more_pages?: true,
        results: hits,
        results_hits: hit_count,
        results_time: time,
        results_id: Ecto.UUID.generate(),
        search: "",
        type: "packages",
        version: default_version,
        filter: %{
          show_collections?: true
        }
      })

    {:ok, socket, temporary_assigns: [results: nil]}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.render_options search={@search} version={@version} type={@type} filter={@filter} />
    <div class="lg:pl-[13.5rem] font-normal">
      <.render_search search={@search} results_hits={@results_hits} results_time={@results_time} />

      <div id={@results_id} phx-hook="InfiniteScroll" phx-update="append" data-page={@page}>
        <div
          :for={r <- @results}
          :if={@results}
          id={"infinite-scroll__#{r.id}"}
          class="px-1 py-3 text-fg/70 text-sm hover:bg-bg_focus/50 rounded-lg"
        >
          <.render_result r={r} type={@type} />
          <div id={r.id} class="hidden pb-2">
            <.render_result_hidden r={r} type={@type} version={@version} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Search")
    |> assign(:proxy, nil)
  end

  @impl true
  def handle_event(
        "search",
        %{
          "key" => _key,
          "value" => search
        },
        socket
      ) do
    socket =
      socket
      |> assign(%{
        search: search,
        page: 0,
        more_pages?: true,
        results_id: Ecto.UUID.generate()
      })
      |> assign_results()

    {:noreply, socket}
  end

  def handle_event(
        "load_next",
        _,
        %{assigns: %{page: page, more_pages?: more_pages?}} = socket
      )
      when page < @page_limit do
    # prevents the users of going "down" when there is nothing else
    page = if more_pages?, do: page + 1, else: page

    socket =
      socket
      |> assign(:page, page)
      |> assign_results()

    {:noreply, socket}
  end

  def handle_event("load_next", %{}, socket) do
    {:noreply, socket}
  end

  #
  # version
  #

  def handle_event("set_version", %{"value" => version}, socket) do
    socket =
      socket
      |> assign(%{version: version})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  #
  # Tabs
  #

  def handle_event("change_type:" <> type, _value, socket) do
    socket =
      socket
      |> assign(%{type: type})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  #
  # Toggles
  #

  def handle_event(
        "toggle_show_collections",
        _key,
        %{assigns: %{filter: filter}} = socket
      ) do
    socket =
      socket
      |> assign(%{filter: %{filter | show_collections?: not filter.show_collections?}})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  def handle_event("toggle_" <> _, _, socket) do
    {:noreply, socket}
  end

  defp assign_results_from_start(socket) do
    socket
    |> assign(%{
      page: 0,
      more_pages?: true,
      results_id: Ecto.UUID.generate()
    })
    |> assign_results()
  end

  defp assign_results(
         %{
           assigns: %{
             search: search,
             page: page,
             filter: filter,
             type: type,
             version: version
           }
         } = socket
       ) do
    %{hits: hits, hit_count: hit_count, time: time} =
      Nix.search_package(
        %{
          q: search,
          limit: @limit,
          offset: @limit * page,
          filter: build_filter(filter)
        },
        type,
        version
      )

    socket
    |> assign(%{
      more_pages?: search != [],
      results: hits,
      results_hits: hit_count,
      results_time: time,
      page: page
    })
  end

  defp build_filter(%{
         show_collections?: show_collections?
       }) do
    [
      (not show_collections? &&
         [
           "loc_lenght = 1"
         ]) || []
    ]
  end
end
