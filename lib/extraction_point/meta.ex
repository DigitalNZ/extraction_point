defmodule ExtractionPoint.Meta do
  import Ecto.Query
  import ExtractionPoint.{ExportUtils, ExtendedField.LabelKey}

  alias ExtractionPoint.{ContentType, Repo, TopicType}

  @derive Jason.Encoder
  defstruct [:table_name, :count, :within_baskets, :columns, :url_json, :url_csv]

  def report() do
    # exclude comments for now
    content_types =
      from(ct in ContentType, where: ct.class_name != "Comment")
      |> Repo.all()
      |> Enum.map(fn type ->
        table_name_root = content_type_base_table_name(type.class_name)
        table_name = "#{prefix()}_#{table_name_root}"
        url_root = table_name_to_base_url(table_name_root)
        [count, baskets] = get_count_and_baskets(table_name)

        %__MODULE__{
          table_name: table_name,
          count: count,
          within_baskets: baskets,
          columns: get_columns_and_types(table_name),
          url_json: "/#{url_root}",
          url_csv: "/#{url_root}.csv"
        }
      end)

    topic_types =
      from(tt in TopicType)
      |> Repo.all()
      |> Enum.map(fn type ->
        table_name_root = to_plural_key(type.name)
        type_key = to_key(type.name)
        table_name = "#{prefix()}_#{table_name_root}"
        [count, baskets] = get_count_and_baskets(table_name)

        %__MODULE__{
          table_name: table_name,
          count: count,
          within_baskets: baskets,
          columns: get_columns_and_types(table_name),
          url_json: "/topics?topic_type=#{type_key}",
          url_csv: "/topics.csv?topic_type=#{type_key}"
        }
      end)

    # distinct basket_keys

    content_types ++ topic_types
  end

  defp content_type_base_table_name(class_name) do
    case class_name do
      "AudioRecording" -> "audio_recordings"
      "Document" -> "documents"
      "StillImage" -> "still_images"
      "User" -> "users"
      "Video" -> "videos"
      "WebLink" -> "web_links"
    end
  end

  defp table_name_to_base_url(table_name), do: table_name |> String.replace("_", "-")

  defp get_count(table_name) do
    from(t in table_name,
      select: count(t.id))
    |> Repo.one()
  end

  defp get_count_and_baskets("extracted_users") do
    [get_count("users"), "N/A"]
  end
  defp get_count_and_baskets(table_name) do
    query = from(t in table_name, select: fragment("distinct(basket_key)"))
    [get_count(table_name), query |> Repo.all()]
  end

  defp get_columns_and_types(table_name) do
    query = "select column_name, data_type from information_schema.columns where table_name = '#{table_name}'"
    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query, []) do
      columns = to_keys(results.columns)

      map_rows(columns, results.rows)
    end
  end
end
