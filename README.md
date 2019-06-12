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
