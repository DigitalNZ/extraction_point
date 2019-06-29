defmodule Mix.Tasks.ExtractionPoint.LoadSql do
  use Mix.Task

  # assume single repo
  alias ExtractionPoint.Repo

  @shortdoc "Loads specified sql file into db. For initial import of data."
  @moduledoc ~S"""
  Loads specified sql file into db. For initial import of data.

  #Usage
  ```
  mix extration_point.load_sql sql_file.sql
  ```
  This will use ecto to load the sql
  """
  def run([sql_file]) do
    Mix.Task.run("ecto.create")

    Mix.Task.run("app.start")

    IO.puts("Loading #{sql_file}...")

    args = [
      "-U",
      Repo.config()[:username],
      "-h",
      Repo.config()[:hostname],
      "-p",
      to_string(Repo.config()[:port]),
      "--quiet",
      "--file",
      sql_file,
      "-vON_ERROR_STOP=1",
      Repo.config()[:database]
    ]

    System.cmd("psql", args, env: [])

    IO.puts("Loading #{sql_file} done")
  end
end
