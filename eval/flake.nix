{
  description = "Nixpkgs to JSON";

  inputs = {
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
  };

  outputs = { self, nixpkgs_stable, nixpkgs_unstable, home-manager, flake-utils }:
    with builtins;
    with nixpkgs_stable.lib;
    let
      params = import ./params.nix;

      pkgs = import nixpkgs_stable {
        system = "x86_64-linux";
        config.android_sdk.accept_license = true;
      };

      pkgs_unstable = import nixpkgs_stable {
        system = "x86_64-linux";
        config.android_sdk.accept_license = true;
      };

      ignore_list = [
        # not necessary to evaluate
        #"drvAttrs"
        #"inputDerivation"

        "lib" # functions
        "pkgsCross" # cross-compiled packages
        "config" # options
        "nixosTests" # nixpkgs tests
        "tests" # functions tests
        "stdenv" # it has meta and a lot of packages have stdenv internally
      ];

      # how much packages per batch
      # can cause stack overflows!
      step = 200;
    in
    rec {

      #
      # API
      #

      getHomeManagerOptions =
        home-manager.packages.x86_64-linux.docs-json.text;

      # divide and conquer for `findSuperPackagesPath`
      getSuperPackagesPath =
        let
          start_of = getAttr params.start_of pkgs_unstable;
        in
        pipe start_of [
          #(x: (debug.traceVal x))
          (mapAttrsToList nameValuePair)
          (lists.sublist (params.start * step) step)
          listToAttrs
          (x: findSuperPackagesPath x (params.start_of))
          lists.flatten
          toJSON
        ];

      # divide and conquer for `findPackagesMeta`
      getPackagesMeta =
        let
          start_of = getAttr params.start_of pkgs_unstable;
        in
        pipe start_of [
          (mapAttrsToList nameValuePair)
          (lists.sublist (params.start * step) step)
          listToAttrs
          (x: findPackagesMeta x (params.start_of))
          lists.flatten
          toJSON
        ];

      #
      # Support
      #

      # counts how much attributes a pkg node has
      # -> attrCount {...pkgs...}
      attrCount = x: pipe x [
        (mapAttrsToList nameValuePair)
        length
      ];

      # traverses the pkgs nodes using a list of names
      # -> getAttr [ "pkgs" "ArchiSteamFarm" ] {...pkgs...}
      getAttr = list: attr:
        lists.last
          (foldl'
            (acc: x: (catAttrs x acc))
            [ attr ] # current pkg node
            list # start_of list
          );

      # GENERIC FUNCTION
      # traverses the pkgs nodes until it find the meta attr
      travelPackages = attr: acc: fn_found: fn_else:
        if isAttrs attr && !(isOption attr) then
          if attr ? meta
            # some attr.meta can be a boolean or string
            # and to avoid cases where the meta attrs can't be
            # evaluated we only get what has platforms
            && (tryEval (isAttrs attr.meta)).value
            && (tryEval (attr.meta.platforms)).success then
            fn_found attr
          else
            pipe attr [
              (mapAttrsToList
                (name: value:
                  if (lists.all (x: x != name) (acc ++ ignore_list))
                    #&& ((debug.traceVal (acc ++ [ name ])) != false)
                    #
                    # if it got rejected by the first if and has meta attr
                    # then its completely broken!!! (and highly explosive)
                    && !(tryEval (isAttrs attr.meta)).value
                    && (tryEval (isAttrs value)).value # only attrs
                    && !(hasAttr name value) # ignore if recursive attr
                  then
                    fn_else name value
                  else
                    [ ]
                ))
            ]
        else
          [ ];

      normalizeMeta = meta: (
        meta
        //
        # sometimes it has a list of lists of platforms
        { platforms = lists.flatten meta.platforms; }
        //
        # ignore maintainers that do not have email
        # like `["roblabla"]`
        (if meta ? maintainers && (lists.any isString meta.maintainers) then
          { maintainers = [ ]; }
        else
          { }
        )
        //
        # normalize .homepage to list
        (if meta ? homepage && !isList meta.homepage then
          { homepage = [ meta.homepage ]; }
        else
          { }
        )
        //
        (if meta ? license then
          {
            licenses = pipe meta [
              (m:
                (if isList m.license then m.license else [ m.license ])
                ++ (if m ? licenses then m.licenses else [ ])
              )
              lists.flatten
              (map (x: (
                if isString x then { shortName = x; } else x
              )
              ))
            ];
          }
        else
          { }
        )

      );

      #
      # Traversers
      #

      # find pkgs nodes that have more than 200 attributes
      # returning results like: {"r":["pkgs","ArchiSteamFarm"]}
      # to be used with findPackagesMeta
      findSuperPackagesPath = attr: acc:
        travelPackages attr acc
          # fn_found
          (attr: [ ])
          # fn_else
          (name: value:
            if (attrCount value) > step then
              { r = acc ++ [ name ]; }
            else
              pipe value [
                (x: findSuperPackagesPath x (acc ++ [ name ]))
                lists.flatten
              ]
          );

      # find pkgs nodes with meta attributes
      # using `normalizeMeta` on the pkgs metadata
      findPackagesMeta = attr: acc:
        travelPackages attr acc
          # fn_found
          (attr:
            {
              path = acc;
              version =
                if (tryEval attr.version).success
                  && attr.version != "" then
                  attr.version
                else
                  if (tryEval attr.meta.version).success
                    && attr.meta.version != "" then
                    attr.meta.version
                  else
                    if (tryEval attr.meta.name).success
                      && attr.meta.name != "" then
                      attr.meta.name
                    else
                      lists.last acc;
              meta =
                if (tryEval attr.meta).success then
                  normalizeMeta attr.meta
                else
                  { };
            }
          )
          # fn_else
          (name: value:
            if (attrCount value) > step then
              [ ]
            else
              pipe value [
                (x: findPackagesMeta x (acc ++ [ name ]))
                lists.flatten
              ]
          );
    };
}
