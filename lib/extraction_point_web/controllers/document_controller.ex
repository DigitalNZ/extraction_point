defmodule ExtractionPointWeb.DocumentController do
  use ExtractionPointWeb, :controller

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/documents.csv"} = conn, params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=documents.csv])
      |> send_chunked(:ok)

    Exporter.list_type(:document, params, fn columns, stream ->
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
    {columns, documents} = Exporter.list_type(:document, params)

    render(conn, :index, columns: columns, documents: documents, meta: params)
  end

  def show(conn, %{"id" => id}) do
    {columns, document} = Exporter.get_type(:document, id)

    render(conn, :show, columns: columns, document: document)
  end
end
