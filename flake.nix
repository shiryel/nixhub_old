{
  description = "NixHub";

  inputs = {
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs_stable, nixpkgs_unstable, flake-utils }:
    with builtins;
    with nixpkgs_stable.lib;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs_stable {
          system = system;
        };

        pkgs_unstable = import nixpkgs_unstable {
          system = system;
        };

        my-nix-eval-jobs = (pkgs_unstable.nix-eval-jobs.overrideAttrs (old: rec {
          patches = [
            ./priv/nix/nix_eval_jobs.patch
          ];
        }));

        packages = with pkgs_unstable; [
          elixir_1_14
          openssl
          locale
          glibcLocalesUtf8
          gnused
          git
          pandoc
          my-nix-eval-jobs
          nix
        ];
      in
      {
        devShell = pkgs.mkShell {
          packages = packages;
        };

        packages.nixhub-deps = pkgs.symlinkJoin {
          name = "nixhub-deps";
          paths = packages;
        };
      }
    );
}
