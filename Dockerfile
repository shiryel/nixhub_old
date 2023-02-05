FROM nixos/nix

#RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
#  && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

COPY priv/nix_eval/tryEval.patch priv/nix_eval/tryEval.patch
COPY flake.nix flake.nix
COPY flake.lock flake.lock

# lets nix develop result cached
RUN nix --experimental-features 'nix-command flakes' develop

# FIXES: error 'variable $src or $srcs should point to the source'
# on nix develop inside docker
COPY priv/nix_eval/nix_sources.sh priv/nix_eval/nix_sources.sh
RUN ./priv/nix_eval/nix_sources.sh ./tmp

RUN nix --experimental-features 'nix-command flakes' develop -c mix local.hex --force
RUN nix --experimental-features 'nix-command flakes' develop -c mix local.rebar --force

ARG MIX_ENV="prod"
ENV MIX_ENV=$MIX_ENV

# install mix dependencies
COPY mix.exs mix.lock ./
RUN nix --experimental-features 'nix-command flakes' develop -c mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN nix --experimental-features 'nix-command flakes' develop -c mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN nix --experimental-features 'nix-command flakes' develop -c mix assets.deploy
RUN nix --experimental-features 'nix-command flakes' develop -c mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/
COPY rel rel

RUN nix --experimental-features 'nix-command flakes' develop -c mix release --path ./

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD ["nix", "--experimental-features", "nix-command flakes", "develop", "-c", "/app/bin/server"]
