defmodule ExtractionPoint.Repo.Migrations.AddPostgisExtension do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION postgis", "DROP EXTENSION postgis"
  end
end
