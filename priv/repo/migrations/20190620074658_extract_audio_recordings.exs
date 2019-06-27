defmodule ExtractionPoint.Repo.Migrations.ExtractAudioRecordings do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.{Contributions, PreviousUrlPatterns, Table}

  alias ExtractionPoint.{ContentType, Repo}

  @type_path_key "audio"
  @table_name "extracted_audio_recordings"
  @class_name "AudioRecording"
  @create_extracted ~s"""
  CREATE TABLE #{@table_name} AS
  SELECT T1.id, title, description, version,
  filename, content_type, size,
  id_path_segment_to_file(T1.id, filename) as relative_file_path,
  basket_id, license_id,
  T1.created_at AS inserted_at, T1.updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  B.urlified_name as basket_key,
  ARRAY[#{path_patterns(@type_path_key)}] AS previous_url_patterns,
  NULL::integer AS creator_id,
  NULL::text AS creator_login,
  NULL::text AS creator_name,
  ARRAY[]::integer[] AS contributor_ids,
  ARRAY[]::text[] AS contributor_logins,
  ARRAY[]::text[] AS contributor_names,
  T1.extended_content FROM audio_recordings T1
  INNER JOIN baskets B ON (basket_id = B.id)
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

    execute(update_with_creator("audio_recordings", @class_name, @table_name))
    execute(update_with_contributors("audio_recordings", @class_name, @table_name))
  end

  def down do
    execute("DROP TABLE #{@table_name}")
  end
end
