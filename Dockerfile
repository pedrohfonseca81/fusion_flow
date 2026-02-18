ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.1.2
ARG DEBIAN_VERSION=bullseye-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

COPY assets assets
RUN cd assets && npm install

COPY priv priv
COPY lib lib
COPY config config
RUN mix assets.setup
RUN mix assets.deploy

RUN mix compile

COPY config/runtime.exs config/

RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  python3 \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PHX_SERVER="true"

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/fusion_flow ./

COPY scripts/entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

USER nobody

ENTRYPOINT ["/app/entrypoint.sh"]
