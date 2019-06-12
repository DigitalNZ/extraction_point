FROM elixir:alpine

RUN apk update && apk add bash build-base postgresql-client

RUN mix local.hex --force \
  && mix local.rebar --force

WORKDIR /app

ADD ./ /app/

ENV MIX_ENV=dev

RUN mix deps.get
RUN mix deps.compile
RUN mix compile
