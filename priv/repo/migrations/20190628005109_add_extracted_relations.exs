defmodule ExtractionPoint.Repo.Migrations.AddExtractedRelations do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.ExtendedField.LabelKey

  alias ExtractionPoint.{TopicType, Repo}

  @table_name "extracted_relations"
  @prefix "extracted"
  @topic_types from(tt in TopicType) |> Repo.all()
  @create_extracted_relations ~s"""
  CREATE TABLE #{@table_name} (
  id integer,
  position integer,
  source_id integer,
  source_table text,
  related_item_id integer,
  related_item_table text,
  inserted_at timestamp,
  updated_at timestamp
  )
  """
  @create_function ~s"""
  CREATE OR REPLACE FUNCTION content_type_table_name(text) returns text as
  $$ SELECT CASE WHEN $1='AudioRecording' THEN 'audio_recordings'
  WHEN $1='Document' THEN 'documents'
  WHEN $1='StillImage' THEN 'still_images'
  WHEN $1='Video' THEN 'videos'
  WHEN $1='WebLink' THEN 'web_links'
  END;
  $$ LANGUAGE sql IMMUTABLE;
  """
  @drop_function ~s"""
  DROP FUNCTION IF EXISTS content_type_table_name(text)
  """

  @source_table_placeholder "__SOURCE_TABLE__"
  @insert_content_into_template ~s"""
  INSERT INTO #{@table_name}
  SELECT T1.id, position,
  topic_id AS source_id, '#{@source_table_placeholder}' AS source_table,
  related_item_id, CONCAT('#{@prefix}_', content_type_table_name(related_item_type)) AS related_item_table,
  T1.created_at AS inserted_at,
  T1.updated_at
  FROM content_item_relations T1
  WHERE EXISTS (SELECT 1
  FROM #{@source_table_placeholder} E
  WHERE E.id = T1.topic_id)
  AND related_item_type != 'Topic'
  """
  # this has to be done for every topic type
  @related_table_placeholder "__RELATED_TABLE__"
  @insert_related_for_topic_type_into_template ~s"""
  INSERT INTO #{@table_name}
  SELECT T1.id, position,
  topic_id AS source_id, '#{@source_table_placeholder}' AS source_table,
  related_item_id, '#{@related_table_placeholder}' AS related_item_table,
  T1.created_at AS inserted_at,
  T1.updated_at
  FROM content_item_relations T1
  JOIN #{@related_table_placeholder} T2 ON (T1.related_item_id = T2.id)
  WHERE EXISTS (SELECT 1
  FROM #{@source_table_placeholder} E
  WHERE E.id = T1.topic_id)
  AND related_item_type = 'Topic'
  """

  def up do
    execute(@create_extracted_relations)

    execute(@create_function)

    # for each topic type table, query content_item_relations for relations that match topic_id
    Enum.each(@topic_types, fn type ->
      source_table_name = "#{@prefix}_#{to_plural_key(type.name)}"

      @insert_content_into_template
      |> String.replace(@source_table_placeholder, source_table_name)
      |> execute()

      # in order to handle topics that are themselves related items while pointing
      # at new tables per topic type, we do the following per topic type
      Enum.each(@topic_types, fn related_type ->
        related_table_name = "#{@prefix}_#{to_plural_key(related_type.name)}"

        @insert_related_for_topic_type_into_template
        |> String.replace(@source_table_placeholder, source_table_name)
        |> String.replace(@related_table_placeholder, related_table_name)
        |> execute()

        flush()
      end)

      flush()
    end)
  end

  def down do
    execute(@drop_function)

    execute("DROP TABLE #{@table_name}")
  end
end
