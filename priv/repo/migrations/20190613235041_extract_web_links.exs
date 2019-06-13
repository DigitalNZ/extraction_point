defmodule ExtractionPoint.Repo.Migrations.ExtractWebLinks do
  use Ecto.Migration

  @create_extracted ~S"""
  CREATE TABLE extracted_web_links AS
  SELECT id, title, description, url,
  basket_id, license_id,
  created_at AS inserted_at, updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  extended_content FROM web_links
  """
  def up do
    execute @create_extracted
    execute "UPDATE extracted_web_links SET tags = '{}' WHERE tags IS NULL"
    execute "ALTER TABLE extracted_web_links ALTER COLUMN tags SET DEFAULT '{}'"
  end

  def down do
    execute "DROP TABLE extracted_web_links"
  end
end
