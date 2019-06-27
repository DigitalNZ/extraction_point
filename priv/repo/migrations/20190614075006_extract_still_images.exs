defmodule ExtractionPoint.Repo.Migrations.ExtractStillImages do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.{PreviousUrlPatterns, Table}

  alias ExtractionPoint.{ContentType, Repo}

  @type_path_key "images"
  @table_name "extracted_still_images"
  @class_name "StillImage"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT T1.id, title, description, version,
  id_path_segment_to_file(O.id, O.filename) as relative_original_file_path,
  ARRAY(SELECT id_path_segment_to_file(R.id, R.filename)
  FROM image_files AS R
  WHERE still_image_id = T1.id AND R.parent_id IS NOT NULL)
  AS relative_resized_file_paths,
  basket_id, license_id,
  T1.created_at AS inserted_at, T1.updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  B.urlified_name as basket_key,
  ARRAY[#{path_patterns(@type_path_key)}] AS previous_url_patterns,
  T1.extended_content FROM still_images T1
  INNER JOIN baskets B ON (basket_id = B.id)
  INNER JOIN image_files O ON (T1.id = O.still_image_id AND O.parent_id IS NULL)
  """
  def up do
    execute(@create_extracted)
    alter_tags(@table_name)

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
