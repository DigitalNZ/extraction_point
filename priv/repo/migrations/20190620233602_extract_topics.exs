defmodule ExtractionPoint.Repo.Migrations.ExtractTopics do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.DataChange.{PreviousUrlPatterns, Table}
  import ExtractionPoint.ExtendedField.LabelKey

  alias ExtractionPoint.{TopicType, Repo}

  @type_path_key "topics"
  @table_placeholder "__TABLE_NAME__"
  @id_placeholder "__TOPIC_TYPE_ID__"
  @prefix "extracted"
  @create_extracted_template ~s"""
  CREATE TABLE #{@table_placeholder} AS
  SELECT T1.id, title, description, version,
  short_summary, index_for_basket_id,
  topic_type_id, basket_id, license_id,
  T1.created_at AS inserted_at, T1.updated_at,
  STRING_TO_ARRAY(raw_tag_list, ', ') AS tags,
  B.urlified_name as basket_key,
  ARRAY[#{path_patterns(@type_path_key)}] AS previous_url_patterns,
  T1.extended_content FROM topics T1
  INNER JOIN baskets B ON (basket_id = B.id)
  WHERE topic_type_id = #{@id_placeholder}
  """

  def up do
    topic_types =
      from(tt in TopicType, preload: :extended_fields)
      |> Repo.all()

    Enum.each(topic_types, fn type ->
      table_name = "#{@prefix}_#{to_plural_key(type.name)}"

      @create_extracted_template
      |> String.replace(@table_placeholder, table_name)
      |> String.replace(@id_placeholder, to_string(type.id))
      |> execute()

      alter_tags(table_name)

      query = type |> TopicType.ancestors()
      ancestors = from(tt in query, preload: :extended_fields) |> Repo.all()

      full_fields =
        ancestors
        |> Enum.reduce(
          type.extended_fields,
          fn ancestor, acc ->
            List.flatten([acc | ancestor.extended_fields])
          end
        )

      add_columns_to_table_from_extended_fields(full_fields, table_name)

      flush()

      load_data_to_new_columns_from_extended_content(full_fields, table_name)

      execute("ALTER TABLE #{table_name} DROP COLUMN extended_content")

      flush()
    end)
  end

  def down do
    from(tt in TopicType, select: tt.name)
    |> Repo.all()
    |> Enum.map(fn name -> to_plural_key(name) end)
    |> Enum.each(fn table_key -> execute("DROP TABLE #{@prefix}_#{table_key}") end)
  end
end