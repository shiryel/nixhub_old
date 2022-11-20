defmodule CoreWeb.SearchLive.Index do
  use CoreWeb, :live_view

  alias Core.Nix

  @limit 30
  @page_limit 20

  @impl true
  def mount(_params, _session, socket) do
    {search, hits, time} = Nix.search_package(%{q: "nix", limit: @limit})

    socket =
      socket
      |> assign(%{
        page: 0,
        more_pages?: true,
        results: search,
        results_hits: hits,
        results_time: time,
        search: "",
        filter: %{
          packages?: true,
          nixos_options?: true,
          home_manager_options?: true,
          show_collections?: true
        }
      })

    {:ok, socket}
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
          "search_form" => %{
            "search_input" => search,
            "get_nixos_options" => nixos_options,
            "get_packages" => packages,
            "get_home_manager_options" => home_manager_options,
            "show_collections" => show_collections
          }
        },
        %{assigns: %{filter: filter}} = socket
      ) do
    packages? = packages == "true"
    nixos_options? = nixos_options == "true"
    home_manager_options? = home_manager_options == "true"
    show_collections? = show_collections == "true"

    socket =
      socket
      |> assign(:search, search)
      |> assign(:filter, %{
        filter
        | packages?: packages?,
          nixos_options?: nixos_options?,
          home_manager_options?: home_manager_options?,
          show_collections?: show_collections?
      })
      |> assign(:page, 0)
      |> assign(:more_pages?, true)
      |> assign_results(reset?: true)

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

  defp assign_results(
         %{
           assigns: %{
             search: search,
             page: page,
             filter: filter,
             results: old_results
           }
         } = socket,
         [reset?: reset?] \\ [reset?: false]
       ) do
    {search, hits, time} =
      Nix.search_package(%{
        q: search,
        limit: @limit,
        offset: @limit * page,
        filter: build_filter(filter)
      })

    results = if reset?, do: search, else: old_results ++ search

    socket
    |> assign(%{
      more_pages?: search != [],
      results: results,
      results_hits: hits,
      results_time: time,
      page: page
    })
  end

  defp build_filter(%{
         packages?: packages?,
         nixos_options?: nixos_options?,
         home_manager_options?: home_manager_options?,
         show_collections?: show_collections?
       }) do
    [
      # TYPE OR
      ["__type__ = ''"] ++
        ((packages? && ["__type__ = package"]) || []) ++
        ((nixos_options? && ["__type__ = nixos_option"]) || []) ++
        ((home_manager_options? && ["__type__ = home_manager_option"]) || [])
    ] ++
      [
        # AND LOC LENGHT (for package only)
        (not show_collections? &&
           [
             "loc_lenght = 1",
             "__type__ = nixos_option",
             "__type__ = home_manager_option"
           ]) ||
          []
      ]
  end

  ##############
  # COMPONENTS #
  ##############
  # Color Palete:
  # Green - Nixos Options
  # Blue - Packages
  # Purple - Home Manager Options

  #
  # Packages
  #

  defp package_line(assigns) do
    ~H"""
    <div phx-click={JS.toggle(to: "##{@package.id}")} class="cursor-pointer">
      <div class="flex justify-between">
        <div class="flex flex-wrap justify-items-start">
          <Heroicons.archive_box class="w-[1rem] h-[1rem] self-center mx-1" />
          <div class="flex shrink px-2 rounded-lg dark:text-zinc-100 bg-blue-100 dark:bg-blue-900 text-base font-medium">
            <p><%= @package.name %></p>
          </div>
          <span :if={@package.unfree} class="ml-2 px-2 rounded-lg bg-red-100 dark:bg-red-700">
            unfree
          </span>
          <span :if={@package.broken} class="ml-2 px-2 rounded-lg bg-orange-100 dark:bg-orange-600">
            broken
          </span>
        </div>

        <p class="italic grow text-right text-xs" }><%= @package.name %></p>
      </div>
      <p class="ml-1 "><%= @package.description %></p>
    </div>
    """
  end

  defp package_long_description(assigns) do
    ~H"""
    <div
      :if={@description}
      class="description my-2 px-4 border-y-[1px] border-slate-200 dark:border-slate-700"
    >
      <%= Phoenix.HTML.Format.text_to_html(@description,
        attributes: [class: "py-2"],
        escape: false,
        insert_brs: false
      ) %>
    </div>
    """
  end

  defp home_and_source(assigns) do
    ~H"""
    <div class="my-1 py-2 flex justify-center gap-6">
      <a :if={@package.homepage} href={List.first(@package.homepage)} target="_blank" class="flex">
        <Heroicons.globe_asia_australia class="text-indigo-400 w-[1rem] h-[1rem] self-center mx-1" />
        Homepage
      </a>
      <a
        :if={@package.position}
        href={"https://github.com/NixOS/nixpkgs/blob/nixos-22.05/#{@package.position}"}
        target="_blank"
        class="flex"
      >
        <Heroicons.code_bracket_square class="text-indigo-400 w-[1rem] h-[1rem] self-center mx-1" />
        Source
      </a>
    </div>
    """
  end

  defp licenses(assigns) do
    ~H"""
    <.detail_list :let={l} list={@package.licenses} label="License">
      <a :if={l.url} href={l.url} class="text-sky-600">
        <%= l.short_name || l.full_name || "license" %>
      </a>
      <p :if={!l.url}><%= l.short_name || l.full_name || "" %></p>
    </.detail_list>
    """
  end

  defp maintainers(assigns) do
    ~H"""
    <.detail_list :let={m} list={@package.maintainers} label="Maintainers">
      <a :if={m.github} href={"https://github.com/#{m.github}"} class="text-sky-600">
        <%= m.name || m.github || "maintainer" %>
      </a>
    </.detail_list>
    """
  end

  defp platforms(assigns) do
    ~H"""
    <.detail_list :let={p} list={@package.platforms} label="Platforms">
      <p><%= p %></p>
    </.detail_list>
    """
  end

  attr :list, :list, default: []
  attr :label, :string
  slot :inner_block, required: true

  defp detail_list(assigns) do
    ~H"""
    <div :if={@list}>
      <h5 class="text-center font-bold"><%= @label %></h5>
      <ul class="px-3 max-h-40 overflow-auto">
        <li :for={x <- @list}>
          <%= render_slot(@inner_block, x) %>
        </li>
      </ul>
    </div>
    """
  end

  #
  # Options
  #

  defp nixos_option_line(assigns) do
    ~H"""
    <div
      phx-click={JS.toggle(to: "##{@option.id}")}
      class="cursor-pointer flex justify-between flex-wrap"
    >
      <div class="flex flex-wrap justify-items-start text-base">
        <Heroicons.cog_6_tooth class="w-[1rem] h-[1rem] self-center mx-1" />
        <div class="flex shrink px-2 rounded-lg bg-green-100 dark:bg-green-900">
          <p class="text-base font-medium"><%= @option.name %></p>
        </div>
      </div>
      <p class="italic text-right grow"><%= @option.type %></p>
    </div>
    """
  end

  defp home_manager_option_line(assigns) do
    ~H"""
    <div
      phx-click={JS.toggle(to: "##{@option.id}")}
      class="cursor-pointer flex justify-between flex-wrap"
    >
      <div class="flex flex-wrap justify-items-start text-base">
        <Heroicons.home class="w-[1rem] h-[1rem] self-center mx-1" />
        <div class="flex shrink px-2 rounded-lg bg-purple-100 dark:bg-purple-900">
          <p class="text-base font-medium"><%= @option.name %></p>
        </div>
      </div>
      <p class="italic text-right grow"><%= @option.type %></p>
    </div>
    """
  end

  defp option_default(assigns) do
    ~H"""
    <div :if={@default} class="my-2 flex gap-2">
      <p class="pl-3 font-bold"><%= "Default:" %></p>
      <p class="code"><%= @default.text %></p>
    </div>
    """
  end

  defp option_example(assigns) do
    ~H"""
    <div :if={@example} class="description my-2 flex gap-4">
      <p class="pl-3 font-bold">Example:</p>
      <p class="code"><%= @example.text %></p>
    </div>
    """
  end

  defp option_declarations(assigns) do
    ~H"""
    <div :if={@declarations} class="my-2">
      <% d = List.first(@declarations) %>
      <a
        href={"https://github.com/NixOS/nixpkgs/blob/nixos-unstable/#{d}"}
        target="_blank"
        class="flex gap-2"
      >
        <p class="pl-3 font-bold">Source:</p>
        <p class="text-blue-500"><%= d %></p>
      </a>
    </div>
    """
  end

  defp option_description(assigns) do
    ~H"""
    <div
      :if={@description}
      class="description border-t border-zinc-200 dark:border-zinc-600 my-2 px-4"
    >
      <%= Phoenix.HTML.Format.text_to_html(@description,
        attributes: [class: "py-2"],
        escape: false,
        insert_brs: false
      ) %>
    </div>
    """
  end
end
