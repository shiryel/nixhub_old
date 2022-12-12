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
        results_id: Ecto.UUID.generate(),
        search: "",
        filter: %{
          packages?: true,
          nixos_options?: true,
          home_manager_options?: true,
          show_collections?: true
        }
      })

    {:ok, socket, temporary_assigns: [results: nil]}
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
  # Toggles
  #

  def handle_event("toggle_packages", %{"key" => "p"}, %{assigns: %{filter: filter}} = socket) do
    socket =
      socket
      |> assign(%{filter: %{filter | packages?: not filter.packages?}})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  def handle_event(
        "toggle_nixos_options",
        %{"key" => "n"},
        %{assigns: %{filter: filter}} = socket
      ) do
    socket =
      socket
      |> assign(%{filter: %{filter | nixos_options?: not filter.nixos_options?}})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  def handle_event(
        "toggle_home_manager_options",
        %{"key" => "h"},
        %{assigns: %{filter: filter}} = socket
      ) do
    socket =
      socket
      |> assign(%{filter: %{filter | home_manager_options?: not filter.home_manager_options?}})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  def handle_event(
        "toggle_show_collections",
        %{"key" => "C"},
        %{assigns: %{filter: filter}} = socket
      ) do
    socket =
      socket
      |> assign(%{filter: %{filter | show_collections?: not filter.show_collections?}})
      |> assign_results_from_start()

    {:noreply, socket}
  end

  def handle_event("toggle_options", %{"key" => "o"}, %{assigns: %{filter: filter}} = socket) do
    socket =
      socket
      |> assign(%{
        filter: %{
          filter
          | nixos_options?: not filter.nixos_options?,
            home_manager_options?: not filter.home_manager_options?
        }
      })
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
             filter: filter
           }
         } = socket
       ) do
    {search, hits, time} =
      Nix.search_package(%{
        q: search,
        limit: @limit,
        offset: @limit * page,
        filter: build_filter(filter)
      })

    socket
    |> assign(%{
      more_pages?: search != [],
      results: search,
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

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :version, :string, default: ""
  attr :description, :string, default: ""
  slot :inner_block, required: true

  defp line_toggle(assigns) do
    ~H"""
    <div phx-click={JS.toggle(to: "##{@id}")} class="cursor-pointer py-3 px-1">
      <div class="flex justify-between flex-wrap">
        <div class="flex flex-wrap justify-items-start gap-1">
          <%= render_slot(@inner_block) %>
          <.button phx-click={JS.dispatch("copy_to_clipboard", detail: @name)} class="bg-transparent">
            <Heroicons.clipboard_document class="icon mx-1.5" />
          </.button>
        </div>

        <p class="italic grow text-right text-xs" }><%= @version %></p>
      </div>
      <p class="ml-7 my-1 text-sm"><%= @description %></p>
    </div>
    """
  end

  attr :value, :any
  attr :label, :string
  attr :event, :string
  attr :key, :string
  attr :keybind_label, :string
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)

  defp toggle(assigns) do
    ~H"""
    <label class={[
      "flex items-center gap-1 px-2 lg:leading-6 text-sm rounded-lg",
      "text-zinc-900 dark:text-zinc-200"
    ]}>
      <input
        type="checkbox"
        checked={@value}
        class={
          [
            "rounded text-zinc-800 border-transparent",
            "ring-transparent focus:ring-transparent",
            # checkbox color
            "bg-slate-400 checked:bg-slate-400 ",
            "dark:bg-slate-900 dark:checked:bg-slate-900",
            # hover checkbox color
            "hover:bg-slate-500 hover:checked:bg-slate-500",
            "dark:hover:bg-slate-600 dark:hover:checked:bg-slate-600"
          ]
        }
        phx-click={JS.dispatch("search") |> JS.push(@event, value: %{key: @key})}
        phx-key={@key}
        phx-window-keydown={JS.dispatch("search") |> JS.push(@event)}
        {@rest}
      />
      <%= @label %>
      <span class="ml-auto">
        <%= @keybind_label %>
      </span>
    </label>
    """
  end

  #
  # Packages
  #

  defp package_line(assigns) do
    ~H"""
    <.line_toggle
      id={@package.id}
      name={@package.name}
      version={@package.version}
      description={@package.description}
    >
      <Heroicons.archive_box mini class="w-[1rem] self-center mx-1 text-blue-700 dark:text-blue-600" />
      <div class="flex shrink text-base font-bold">
        <p><%= @package.name %></p>
      </div>
      <span :if={@package.unfree} class="ml-2 px-2 rounded-lg bg-red-100 dark:bg-red-700">
        unfree
      </span>
      <span :if={@package.broken} class="ml-2 px-2 rounded-lg bg-orange-100 dark:bg-orange-600">
        broken
      </span>
    </.line_toggle>
    """
  end

  defp package_long_description(assigns) do
    ~H"""
    <div
      :if={@description}
      class="
        description 
        my-2 mx-4 px-4 py-3
        border-[1px] rounded-lg border-slate-200 dark:border-slate-700
      "
    >
      <%= Phoenix.HTML.Format.text_to_html(@description,
        attributes: [class: "py-2"],
        escape: false,
        insert_brs: false
      ) %>
    </div>
    """
  end

  # Note: self-center is used to align the text in case that
  # the package has more than one license
  defp home_and_source(assigns) do
    ~H"""
    <div class="my-1 py-2 flex justify-between">
      <div class="flex justify-start gap-4 w-full ml-4">
        <.link_button
          :if={@package.homepage}
          href={List.first(@package.homepage)}
          target="_blank"
          class="flex pl-1 pr-3"
        >
          <Heroicons.globe_asia_australia class="icon self-center mx-1" />
          <p class="self-center">Homepage</p>
        </.link_button>
        <.link_button
          :if={@package.position}
          href={"https://github.com/NixOS/nixpkgs/blob/nixos-22.05/#{@package.position}"}
          target="_blank"
          class="flex pl-1 pr-3"
        >
          <Heroicons.code_bracket_square class="icon self-center mx-1" />
          <p class="self-center">Source</p>
        </.link_button>
      </div>
      <div class="flex flex-nowrap flex-row mr-6">
        <p class="self-center">Licenses:</p>
        <.licenses package={@package} />
      </div>
    </div>
    """
  end

  defp licenses(assigns) do
    ~H"""
    <ul class="px-3 max-h-10 overflow-auto">
      <li :for={l <- @package.licenses} class="flex flex-wrap gap-2">
        <a :if={l.url} href={l.url} class="text-sky-600">
          <%= l.short_name || l.full_name || "license" %>
        </a>
        <p :if={!l.url}><%= l.short_name || l.full_name || "" %></p>
      </li>
    </ul>
    """
  end

  defp maintainers(assigns) do
    ~H"""
    <.detail_list :let={m} list={@package.maintainers} label="Maintainers">
      <a :if={m.github} href={"https://github.com/" <> m.github} class="text-sky-600">
        <%= m.name || m.github || "maintainer" %>
      </a>
      <.link_button
        :if={m.email}
        href={"mailto:" <> m.email}
        class="bg-transparent dark:bg-transparent"
      >
        <Heroicons.envelope class="icon mx-1" />
      </.link_button>
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
        <li :for={x <- @list} class="flex flex-wrap gap-2">
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
    <.line_toggle id={@option.id} name={@option.name} version={@option.type}>
      <Heroicons.cog_6_tooth
        mini
        class="w-[1rem] self-center mx-1 text-green-700 dark:text-green-600"
      />
      <div class="flex shrink">
        <p class="text-base font-bold"><%= @option.name %></p>
      </div>
    </.line_toggle>
    """
  end

  defp home_manager_option_line(assigns) do
    ~H"""
    <.line_toggle id={@option.id} name={@option.name} version={@option.type}>
      <Heroicons.home mini class="w-[1rem] self-center mx-1 text-purple-600 dark:text-purple-500" />
      <div class="flex shrink">
        <p class="text-base font-bold"><%= @option.name %></p>
      </div>
    </.line_toggle>
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

  defp nixos_option_declarations(assigns) do
    ~H"""
    <div :if={@declarations} class="flex gap-2 my-2">
      <% d = List.first(@declarations) %>
      <p class="pl-3 font-bold">Source:</p>
      <.link_button
        href={"https://github.com/NixOS/nixpkgs/blob/nixos-unstable/#{d}"}
        target="_blank"
        class="px-2"
      >
        <p class="text-blue-500"><%= d %></p>
      </.link_button>
    </div>
    """
  end

  defp home_manager_option_declarations(assigns) do
    ~H"""
    <div :if={@declarations} class="flex gap-2 my-2">
      <% d = List.first(@declarations) %>
      <p class="pl-3 font-bold">Source:</p>
      <.link_button
        href={"https://github.com/nix-community/home-manager/blob/nixos-unstable/#{d}"}
        target="_blank"
        class="px-2"
      >
        <p class="text-blue-500"><%= d %></p>
      </.link_button>
    </div>
    """
  end

  defp option_description(assigns) do
    ~H"""
    <div
      :if={@description}
      class="
        description 
        my-2 mx-4 px-4 py-3
        border-[1px] rounded-lg border-slate-200 dark:border-slate-700
      "
    >
      <%= Phoenix.HTML.Format.text_to_html(@description,
        attributes: [class: "py-1"],
        escape: false,
        insert_brs: false
      ) %>
    </div>
    """
  end
end
