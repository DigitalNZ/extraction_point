defmodule ExtractionPoint.Repo.Migrations.ExtractWebLinks do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.Table

  alias ExtractionPoint.{ContentType, Repo}

  @table_name "extracted_web_links"
  @class_name "WebLink"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT id, title, description, url,
  basket_id, license_id,
  created_at AS inserted_at, updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  extended_content FROM web_links
  """
  def up do
    execute(@create_extracted)
    alter_tags(@table_name)

    content_type =
      Repo.get_by(from(ct in ContentType, preload: :extended_fields), class_name: @class_name)

    add_columns_to_table_from_extended_fields(content_type, @table_name)

    flush()

    load_data_to_new_columns_from_extended_content(content_type, @table_name)

    execute "ALTER TABLE #{@table_name} DROP COLUMN extended_content"
  end

  def down do
    execute("DROP TABLE #{@table_name}")
  end
end
