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

        packages = with pkgs_unstable; [
          elixir_1_14
          openssl
          locale
          glibcLocalesUtf8
          gnused
          git
          pandoc

          # Nix
          (nix.overrideAttrs (old: rec {
            doInstallCheck = false;
            patches = old.patches ++ [
              # FIXES:
              # - https://github.com/NixOS/nix/pull/5564
              # - https://github.com/NixOS/nixpkgs/issues/31884
              # - https://github.com/NixOS/nixpkgs/issues/107539
              ./priv/nix_eval/tryEval.patch
            ];
          }))
        ];
      in
      rec {
        devShell = pkgs.mkShell {
          packages = packages;
        };
      }
    );
}
