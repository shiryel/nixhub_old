defmodule CoreExternal.Nixpkgs.Adapter do
  @doc """
    Eval with nix-eval-jobs
  """

  require Logger

  @behaviour CoreExternal.Nixpkgs

  @nix "nix --experimental-features 'nix-command flakes'"

  @impl true
  def eval(%{repo: repo, branch: branch}) do
    tmp = System.tmp_dir!()

    Logger.info("Saving files to: #{inspect(tmp)}")

    flake = """
    {
      inputs = {
        nixpkgs.url = "#{repo}/#{branch}";
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
        in
        {
          get = pkgs;
        };
    }
    """

    File.write!("#{tmp}/flake.nix", flake)

    Logger.info("Updating flake #{branch} ...")

    System.shell("""
      rm #{tmp}/packages.json
      rm #{tmp}/errors.log

      #{@nix} flake update path:#{tmp}#
    """)

    Logger.info("Running nix-eval-jobs ...")

    workers = div(System.schedulers_online(), 2)

    {_, 0} =
      System.shell("""
        nix-eval-jobs --quiet --check-cache-status --meta --gc-roots-dir #{tmp}/gcroot --workers #{workers} --flake path:#{tmp}#get >> #{tmp}/packages.json 2>> #{tmp}/errors.log

        # REMOVE ERRORS
        sed -i.original '/,"error":"error:\ /d' packages.json

        # SORT BY CACHED FIRST
        sed '/"isCached":false/d' packages.json > packages_sorted.json
        sed '/"isCached":true/d' packages.json >> packages_sorted.json
      """)

    Logger.info("nix-eval-jobs finished")

    File.stream!("#{tmp}/packages_ordened.json")
  end
end
