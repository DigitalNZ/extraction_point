# ExtractionPoint

WIP - Tools for processing Kete data after it has been exported in
PostgreSQL importable form

## Requirements

Expects [Docker](https://www.docker.com) to be up and running and
[`docker-compose`](https://docs.docker.com/compose/) to be available
on machine.

## Usage

You'll need a sql file that is an export of a Kete site's data via
[Kete extraction](https://github.com/walter/kete_extraction).

The first step is to import that data. This will trigger `docker` and
`docker-compose` to set up the necessary images and containers on the
machine. So the first time you run any of the commands may be slow.

```sh
docker-compose run app mix extraction_point.load_sql _the_kete_export_file.sql_
```

If you need to undo last migration (you can do this repeatedly until
at right spot), you can rollback.

```sh
docker-compose run app mix ecto.rollback
```

_Note: this tool spins up a container for PostgreSQL to run. It
persists data under `docker/data/postgres` between command runs._

_If you want to start from scratch or clean things out, do
`rm -rf docker/data/postgres/*`._

You can also examine the data via a `psql` session or through the
Elixir application via `iex`.

For `psql` for direct sql access:

```sh
docker-compose run app psql -h db -U 'postgres` extraction_point_dev
```

and here is for `iex`:

```sh
docker-compose run app iex -S mix
```
