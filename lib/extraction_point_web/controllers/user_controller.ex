defmodule ExtractionPointWeb.UserController do
  use ExtractionPointWeb, :controller

  import ExtractionPoint.CSVUtils

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/users.csv"} = conn, params) do
    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=users.csv])
      |> send_chunked(:ok)

    Exporter.list_type(:user, params, fn columns, stream ->
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

  def index(conn, params) do
    {columns, users} = Exporter.list_type(:user, params)

    render(conn, :index, columns: columns, users: users, meta: params)
  end

  def show(conn, %{"id" => id}) do
    {columns, user} = Exporter.get_type(:user, id)

    render(conn, :show, columns: columns, user: user)
  end
end
