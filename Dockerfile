FROM nixos/nix

#RUN nix-channel --update
#RUN nix-env -iA nixpkgs.elixir
#RUN nix-env -iA nixpkgs.openssl
#RUN nix-env -iA nixpkgs.locale
#RUN nix-env -iA nixpkgs.glibcLocalesUtf8
#RUN nix-env -iA nixpkgs.gnused
#RUN nix-env -iA nixpkgs.git
#RUN nix-env -iA nixpkgs.pandoc
#RUN nix-env -iA nixpkgs.nix-eval-jobs

WORKDIR /app

# same as `nix-env -iA $PKG` for each package
# https://blog.prag.dev/installing-from-a-nix-flake
COPY priv priv
COPY flake.nix flake.nix
COPY flake.lock flake.lock
RUN nix --experimental-features 'nix-command flakes' build path:.#nixhub-deps --profile /app/.nix-profile
ENV PATH="/app/.nix-profile/bin:${PATH}"

ARG MIX_ENV="prod"
ENV MIX_ENV=$MIX_ENV

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN mix local.hex --force
RUN mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY lib lib
COPY assets assets

RUN mix assets.deploy
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/
COPY rel rel

RUN mix release --path ./

CMD ["/app/bin/server"]
