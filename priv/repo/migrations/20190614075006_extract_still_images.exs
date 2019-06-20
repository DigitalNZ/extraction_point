defmodule ExtractionPoint.Repo.Migrations.ExtractStillImages do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.Table

  alias ExtractionPoint.{ContentType, Repo}

  @table_name "extracted_still_images"
  @class_name "StillImage"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT id, title, description, version,
  basket_id, license_id,
  created_at AS inserted_at, updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  extended_content FROM still_images
  """
  def up do
    execute(@create_extracted)
    alter_tags(@table_name)

    type =
      Repo.get_by(from(ct in ContentType, preload: :extended_fields), class_name: @class_name)

    add_columns_to_table_from_extended_fields(type, @table_name)

    flush()

    load_data_to_new_columns_from_extended_content(type, @table_name)

    execute("ALTER TABLE #{@table_name} DROP COLUMN extended_content")
  end

  def down do
    execute("DROP TABLE #{@table_name}")
  end
end
