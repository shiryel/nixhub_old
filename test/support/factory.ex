defmodule Core.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Core.Repo

  alias Core.Nix.{Derivation, Package}
  alias Core.Nix.Derivation.{License, Maintainer}
  alias Core.Nix.Version

  def package_factory do
    %Package{
      attr: "elixir",
      attr_path: ["elixir"],
      attr_aliases: [],
      name: sequence(:name, &"package-#{&1}"),
      position: sequence(:position, &"/pkgs/#{&1}.nix#L7"),
      version: build(:version),
      derivation: build(:derivation)
    }
  end

  def version_factory do
    %Version{
      name: "stable",
      repo: "github.com/nixOS/nixpkgs",
      branch: "22.11"
    }
  end

  def derivation_factory do
    %Derivation{
      drv_path: "/nix/store/dylf93ym0g8kd06vxcm9qkdapp2cm5qc-elixir-1.13.4.drv",
      available: true,
      broken: false,
      description: "A functional, meta-programming aware language built on top of the Erlang VM",
      homepage: ["https://elixir-lang.org/"],
      insecure: false,
      is_cached: true,
      outputs_to_install: ["out"],
      platforms: ["any"],
      long_description:
        "Elixir is a functional, meta-programming aware language built on top of the Erlang VM. It is a dynamic language with flexible syntax and macro support that leverages Erlang's abilities to build concurrent, distributed and fault-tolerant applications with hot code upgrades.",
      unfree: false,
      unsupported: false,
      licenses: [build(:license)],
      maintainers: [build(:maintainer)]
    }
  end

  def license_factory do
    %License{
      spdx_id: "GPL-2.0-only",
      short_name: "gpl2Only",
      full_name: "GNU General Public License v2.0 only",
      free: true,
      deprecated: false,
      url: "https://spdx.org/licenses/GPL-2.0-only.html"
    }
  end

  def maintainer_factory do
    %Maintainer{
      github_id: 35_617_139,
      github: "fennec",
      email: "fennec@example.com",
      name: "fennec"
    }
  end
end
