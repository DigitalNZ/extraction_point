defmodule ExtractionPoint.Repo.Migrations.ExtractWebLinks do
  use Ecto.Migration

  import Ecto.Query

  alias ExtractionPoint.{ContentType, ExtendedField, Repo}

  @table_name "extracted_web_links"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT id, title, description, url,
  basket_id, license_id,
  created_at AS inserted_at, updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  extended_content FROM web_links
  """
  def up do
    execute @create_extracted
    execute "UPDATE #{@table_name} SET tags = '{}' WHERE tags IS NULL"
    execute "ALTER TABLE #{@table_name} ALTER COLUMN tags SET DEFAULT '{}'"

    content_type = Repo.get_by(from(ct in ContentType, preload: :extended_fields), class_name: "WebLink")

    alterations = Enum.reduce(
      content_type.extended_fields,
      [],
      fn ef, acc -> acc ++ ExtendedField.add_to_table_sql(ef, @table_name) end)

    Enum.each(alterations, fn s -> execute s end)

    execute "ALTER TABLE #{@table_name} DROP COLUMN extended_content"
  end

  def down do
    execute "DROP TABLE #{@table_name}"
  end
end
