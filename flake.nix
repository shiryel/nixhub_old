{
  description = "NixHub";

  inputs = {
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs_stable, flake-utils }:
    with builtins;
    with nixpkgs_stable.lib;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs_stable {
          system = system;
        };

        packages = with pkgs; [
          (nix.overrideAttrs (old: rec {
            patches = old.patches ++ [
              # FIXES:
              # - https://github.com/NixOS/nix/pull/5564
              # - https://github.com/NixOS/nixpkgs/issues/31884
              # - https://github.com/NixOS/nixpkgs/issues/107539
              ./eval/tryEval.patch
            ];
          }))
          pandoc
        ];
      in
      rec {
        devShell = pkgs.mkShell {
          packages = packages;
        };
      }
    );
}
