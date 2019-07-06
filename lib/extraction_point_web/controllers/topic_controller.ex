defmodule ExtractionPointWeb.TopicController do
  use ExtractionPointWeb, :controller

  import ExtractionPoint.CSVUtils

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/topics.csv"} = conn, %{"topic_type" => topic_type} = params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=#{topic_type}.csv])
      |> send_chunked(:ok)

    Exporter.list_type(topic_type, params, fn columns, stream ->
      conn |> chunk(@bom)

      headers =
        [columns]
        |> CSVParser.dump_to_iodata()
        |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

      conn |> chunk(headers)

      for result <- stream do
        csv_rows =
          result.rows
          |> Enum.map(fn row -> values_to_stringables(row) end)
          |> CSVParser.dump_to_iodata()
          |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

        conn |> chunk(csv_rows)
      end
    end)

    conn
  end

  def index(conn, %{"topic_type" => topic_type} = params) do
    {columns, topics} = Exporter.list_type(topic_type, params)

    render(conn, :index, columns: columns, topics: topics, meta: params)
  end

  def show(conn, %{"id" => id, "topic_type" => topic_type}) do
    {columns, topic} = Exporter.get_type(topic_type, id)

    render(conn, :show, columns: columns, topic: topic)
  end
end
