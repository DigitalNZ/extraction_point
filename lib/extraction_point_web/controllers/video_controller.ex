defmodule ExtractionPointWeb.VideoController do
  use ExtractionPointWeb, :controller

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/videos.csv"} = conn, params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=videos.csv])
      |> send_chunked(:ok)

    Exporter.list_type(:video, params, fn columns, stream ->
      conn |> chunk(@bom)

      headers =
        [columns]
        |> CSVParser.dump_to_iodata()
        |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

      conn |> chunk(headers)

      for result <- stream do
        csv_rows =
          result.rows
          |> CSVParser.dump_to_iodata()
          |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

        conn |> chunk(csv_rows)
      end
    end)

    conn
  end

  def index(conn, params) do
    {columns, videos} = Exporter.list_type(:video, params)

    render(conn, :index, columns: columns, videos: videos, meta: params)
  end

  def show(conn, %{"id" => id}) do
    {columns, video} = Exporter.get_type(:video, id)

    render(conn, :show, columns: columns, video: video)
  end
end
