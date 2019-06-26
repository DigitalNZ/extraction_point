defmodule ExtractionPoint.Repo.Migrations.ExtractUsers do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.{PreviousUrlPatterns, Table}

  alias ExtractionPoint.{ContentType, Repo}

  @type_path_key "users"
  @table_name "extracted_#{@type_path_key}"
  @class_name "User"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT id, login, email, resolved_name as display_name,
  activated_at, banned_at,
  created_at AS inserted_at, updated_at,
  ARRAY[#{path_patterns(@type_path_key)}] AS previous_url_patterns,
  extended_content FROM users
  """
  def up do
    execute(@create_extracted)

    type =
      Repo.get_by(from(ct in ContentType, preload: :extended_fields), class_name: @class_name)

    add_columns_to_table_from_extended_fields(type.extended_fields, @table_name)

    flush()

    load_data_to_new_columns_from_extended_content(type.extended_fields, @table_name)

    execute("ALTER TABLE #{@table_name} DROP COLUMN extended_content")
  end

  def down do
    execute("DROP TABLE #{@table_name}")
  end
end
