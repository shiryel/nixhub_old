# nix-eval-jobs --meta --flake path:priv/nix_eval2#get
{
  description = "Nixpkgs to JSON";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs, }:
    with builtins;
    with nixpkgs.lib;
    let
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
        allowBroken = true;
        allowUnsupportedSystem = true;
        permittedInsecurePackages = true;
        input-fonts.acceptLicense = true;
        joypixels.acceptLicense = true;
        segger-jlink.acceptLicense = true;
      };

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = config;
      };

      ignore_list = [
        "lib" # functions
        "pkgsCross" # cross-compiled packages
        "config" # options
        "nixosTests" # nixpkgs tests
        "tests" # functions tests
        "stdenv" # it has meta and a lot of packages have stdenv internally
        "iosSdkPkgs"
      ];
    in
    rec {
      #
      # API
      #

      get = pkgs;

      getSize = pipe pkgs [
        (mapAttrsToList nameValuePair)
        length
        toJSON
      ];

      getMidSize = { size ? 100, offset ? 0 }:
        pipe
          pkgs
          [
            (mapAttrsToList nameValuePair)
            (lists.sublist (offset * size) size)
            listToAttrs
            (x: findPackagesMeta x [ ])
            lists.flatten
            length
            # WORKAROUND: Nix does not accept `--arg` on flakes[1], so we use
            # nix-eval-jobs, and them we get the size using a derivation name
            # [1] - https://github.com/NixOS/nix/issues/3843#issuecomment-661710951
            (x: derivation {
              name = toJSON x;
              builder = ":";
              system = "x86_64-linux";
            })
          ];

      getSlice = { size ? 100, offset ? 0, mid_size ? 1, mid_offset ? 0 }:
        pipe
          pkgs
          [
            (mapAttrsToList nameValuePair)
            # WORKAROUND: Nix can't evaluate every package, even with
            # nix-eval-jobs, so we evaluate one by one :)
            (lists.sublist (offset * size) size)
            listToAttrs
            (x: findPackagesMeta x [ ])
            lists.flatten
            # WORKAROUND: Nix can't handle big amounts of data, and some
            # grouped packages are too big for it, so we need to split the split
            (lists.sublist (mid_offset * mid_size) mid_size)
            (foldl (attrsets.recursiveUpdate) { })
          ];

      #
      # Support
      #

      # GENERIC FUNCTION
      # traverses the pkgs nodes until it find the meta attr
      travelPackages = attr: acc: fn_found: fn_else:
        if isAttrs attr && !(isOption attr) then
          if attrsets.isDerivation attr
          #&& ((debug.traceVal acc) != false) 
          then
          #{name = acc; value = attr;}
            fn_found (attrsets.setAttrByPath acc attr)
          else
            pipe attr [
              (mapAttrsToList
                (name: value:
                  if (lists.all (x: x != name) (acc ++ ignore_list))
                    && !((length acc) > 1)
                    && !(strings.hasPrefix "androidndkPkgs" name)
                    #&& ((debug.traceVal (acc ++ [ name ])) != false)
                    #
                    # if it got rejected by the first if and has meta attr
                    # then its completely broken!!! (and highly explosive)
                    #&& !(tryEval (attr ? meta && isAttrs attr.meta)).value
                    && (tryEval (isAttrs value)).value # only attrs
                    #&& ((debug.traceVal (acc ++ [ name ])) != false)
                    && !(tryEval (hasAttr name value)).value # ignore if recursive attr
                  #&& ((debug.traceVal (acc ++ [ name ])) != false)
                  then
                    fn_else name value
                  else
                    [ ]
                ))
            ]
        else
          [ ];

      #
      # Traversers
      #

      # find pkgs nodes with meta attributes
      # using `normalizeMeta` on the pkgs metadata
      findPackagesMeta = attr: acc:
        travelPackages attr acc
          # fn_found
          (attr: attr)
          # fn_else
          (name: value:
            pipe value [
              (x: findPackagesMeta x (acc ++ [ name ]))
              lists.flatten
            ]
          );
    };
}
