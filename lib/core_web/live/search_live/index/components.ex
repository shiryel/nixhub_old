defmodule CoreWeb.SearchLive.Index.Components do
  @moduledoc false

  use Phoenix.Component

  import CoreWeb.CoreComponents

  alias Phoenix.LiveView.JS

  def render_options(assigns) do
    ~H"""
    <div class={[
      "hidden lg:block fixed",
      "right-auto left-[max(0px,calc(50%-40rem))] top-[calc(50%-10rem)]",
      "w-[17.5rem] px-8"
    ]}>
      <div class="flex gap-2 flex-col p-3 bg-bg_focus rounded-lg">
        <select
          class={[
            "mt-1 block w-full py-2 px-3 text-fg",
            "border border-gray-300",
            "bg-bg/10 rounded-md shadow-sm",
            "focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
          ]}
          phx-click="set_version"
        >
          <option><%= @version %></option>
          <option :for={v <- Core.Nix.list_versions() |> List.delete(@version)}>
            <%= v %>
          </option>
        </select>
        <.tab_button phx-click="change_type:packages" active={@type == "packages"}>
          Packages <.hit_count search={@search} type="packages" version={@version} />
        </.tab_button>
        <.tab_button phx-click="change_type:nixos_options" active={@type == "nixos_options"}>
          NixOS options <.hit_count search={@search} type="nixos_options" version={@version} />
        </.tab_button>
        <.tab_button
          phx-click="change_type:home_manager_options"
          active={@type == "home_manager_options"}
        >
          HM options <.hit_count search={@search} type="home_manager_options" version={@version} />
        </.tab_button>
        <.toggle
          value={@filter.show_collections?}
          label="show collections"
          keybind_label="Shift C"
          event="toggle_show_collections"
          key="c"
        />
      </div>
    </div>
    """
  end

  defp hit_count(assigns) do
    ~H"""
    <p class="p-1 text-xs text-cyan inline italic">
      <%= Core.Nix.search_package(%{q: @search, attributesToRetrieve: []}, @type, @version).hit_count %>
    </p>
    """
  end

  attr :active, :boolean, required: true
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)
  slot :inner_block, required: true

  def tab_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        (@active && "bg-fg/30 text-bg") ||
          "bg-bg/70 text-fg",
        "hover:bg-fg/40",
        "rounded-lg focus:border-slate-800 ",
        "focus:ring-2 focus:ring-zinc-800/3"
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :value, :any
  attr :label, :string
  attr :event, :string
  attr :key, :string
  attr :keybind_label, :string
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)

  def toggle(assigns) do
    ~H"""
    <label class={[
      "flex items-center gap-1 px-2 lg:leading-6 text-sm rounded-lg",
      "text-fg"
    ]}>
      <input
        type="checkbox"
        checked={@value}
        class={
          [
            "rounded border-transparent",
            "ring-transparent focus:ring-transparent",
            # checkbox color
            "bg-bg checked:bg-fg/40",
            # hover checkbox color
            "hover:bg-bg/50 hover:checked:bg-fg/70"
          ]
        }
        phx-click={JS.dispatch("search") |> JS.push(@event)}
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

  def render_search(assigns) do
    ~H"""
    <div class="sticky top-0 z-10 p-2 bg-bg/75">
      <div class="flex">
        <div class="w-full">
          <input
            autofocus
            value={@search}
            class={
              [
                "w-full rounded-lg border-zinc-300 py-[7px] px-[11px]",
                # border
                "border-bg",
                "focus:border-bg_focus focus:ring-bg_focus",
                "focus:outline-none focus:ring-4",
                # background
                "bg-fg/70",
                # text
                "text-bg",
                "sm:text-md sm:leading-6",
                # placeholder
                "placeholder:text-transparent md:placeholder:text-right",
                "md:placeholder:text-bg/50"
              ]
            }
            phx-keydown={JS.dispatch("search") |> JS.push("search")}
            phx-debounce="0"
            id="search-bar"
            phx-hook="FocusOnKeydown"
            placeholder="'S' to search | 'Shift+S' to clean | 'Enter+key' to filter"
          />
        </div>
        <div class={[
          "flex flex-col whitespace-nowrap ml-1 self-center w-16",
          "text-right text-xs text-blue-400/70"
        ]}>
          <p><%= @results_hits %> hits</p>
          <p><%= @results_time %> ms</p>
        </div>
      </div>
    </div>
    """
  end

  def render_result(assigns) do
    ~H"""
    <.button
      phx-click={JS.dispatch("copy_to_clipboard", detail: @r.attr)}
      class="bg-transparent hover:bg-bg rounded-lg"
    >
      <Heroicons.clipboard_document class="icon mx-1.5" />
    </.button>

    <a
      phx-click={JS.toggle(to: "##{@r.id}") |> JS.toggle(to: "#description-#{@r.id}")}
      class={[
        "text-fg text-base font-medium cursor-pointer",
        "underline underline-offset-4 decoration-1 decoration-cyan/40"
      ]}
    >
      <%= @r.attr %>
    </a>
    <span :if={@type == "packages" and @r.unfree} class="ml-1 px-1 rounded-md bg-red/70">
      unfree
    </span>

    <p :if={@type == "packages"} class="inline italic grow float-right text-right" }>
      <%= @r.version %>
    </p>

    <div id={"description-#{@r.id}"}>
      <.description id={@r.id} description={@r.description} />
    </div>
    """
  end

  def render_result_hidden(assigns) do
    ~H"""
    <div>
      <.description description={Map.get(@r, :long_description) || @r.description} />
      <div :if={@type == "packages"} class="my-1 py-2 flex justify-center">
        <div>
          <.link_button
            :if={@r.homepage}
            href={List.first(@r.homepage)}
            target="_blank"
            class="flex pl-1 pr-3"
          >
            <Heroicons.globe_asia_australia class="icon self-center" />
            <p class="inline self-center pl-1">Homepage</p>
          </.link_button>
        </div>
        <div class="flex flex-nowrap flex-row mr-6">
          <p class="self-center">Licenses:</p>
          <.licenses package={@r} />
        </div>
      </div>

      <div :if={Map.get(@r, :default)} class="flex gap-2">
        <p><%= "Default:" %></p>
        <p class="code"><%= @r.default.text %></p>
      </div>

      <div :if={Map.get(@r, :example)} class="description flex gap-4">
        <p>Example:</p>
        <p class="code"><%= @r.example.text %></p>
      </div>

      <div>
        <.link_button
          href={
            case @type do
              "packages" ->
                "https://github.com/NixOS/nixpkgs/blob/nixos-#{@version}/#{@r.position}"

              "nixos_options" ->
                "https://github.com/NixOS/nixpkgs/blob/nixos-#{@version}/#{List.first(@r.declarations)}"

              "home_manager_options" ->
                hm_version =
                  if @version == "unstable" do
                    "master"
                  else
                    "release-#{@version}"
                  end

                "https://github.com/nix-community/home-manager/blob/#{hm_version}/#{List.first(@r.declarations)}"
            end
          }
          target="_blank"
        >
          <p class="text-blue-500 text-center">
            <%= if Map.get(@r, :declarations) do
              List.first(@r.declarations)
            else
              @r.position
            end %>
          </p>
        </.link_button>
      </div>
    </div>
    """
  end

  defp description(assigns) do
    ~H"""
    <div class="">
      <%= Phoenix.HTML.Format.text_to_html(@description || "",
        attributes: [class: "py-1"],
        escape: false,
        insert_brs: false
      ) %>
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

  # defp maintainers(assigns) do
  #  ~H"""
  #  <.detail_list :let={m} list={@package.maintainers} label="Maintainers">
  #    <a :if={m.github} href={"https://github.com/" <> m.github} class="text-sky-600">
  #      <%= m.name || m.github || "maintainer" %>
  #    </a>
  #    <.link_button
  #      :if={m.email}
  #      href={"mailto:" <> m.email}
  #      class="bg-transparent dark:bg-transparent"
  #    >
  #      <Heroicons.envelope class="icon mx-1" />
  #    </.link_button>
  #  </.detail_list>
  #  """
  # end

  # attr :list, :list, default: []
  # attr :label, :string
  # slot :inner_block, required: true

  # defp detail_list(assigns) do
  #  ~H"""
  #  <div :if={@list}>
  #    <h5 class="text-center font-bold"><%= @label %></h5>
  #    <ul class="px-3 max-h-40 overflow-auto">
  #      <li :for={x <- @list} class="flex flex-wrap gap-2">
  #        <%= render_slot(@inner_block, x) %>
  #      </li>
  #    </ul>
  #  </div>
  #  """
  # end

  # defp platforms(assigns) do
  #  ~H"""
  #  <.detail_list :let={p} list={@package.platforms} label="Platforms">
  #    <p><%= p %></p>
  #  </.detail_list>
  #  """
  # end
end
