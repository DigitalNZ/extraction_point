defmodule ExtractionPoint.Repo.Migrations.UpdateNullMultipleExtendedFields do
  use Ecto.Migration

  def up do
    execute("UPDATE extended_fields set multiple = false where multiple is null")
  end
end
