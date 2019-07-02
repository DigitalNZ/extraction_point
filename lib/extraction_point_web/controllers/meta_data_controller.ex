defmodule ExtractionPointWeb.MetaDataController do
  use ExtractionPointWeb, :controller

  import ExtractionPoint.CSVUtils

  alias ExtractionPoint.Meta

  action_fallback ExtractionPointWeb.FallbackController

  @bom :unicode.encoding_to_bom({:utf16, :little})

  def index(%Plug.Conn{request_path: "/meta.csv"} = conn, _params) do
    meta = Meta.report()

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s[inline; filename=meta.csv])
      |> send_chunked(:ok)

    conn |> chunk(@bom)

    columns =
      List.first(meta)
      |> Map.keys()
      |> Enum.map(fn c -> to_string(c) end)
      |> Enum.filter(fn c -> c != "__struct__" end)
      |> Enum.to_list()

    headers = CSVParser.dump_to_iodata([columns])
      |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

    conn |> chunk(headers)

    rows =
      meta
      |> Enum.map(fn m -> Map.values(m) end)
      |> Enum.map(fn m -> remove_module_value(m) end)
      |> Enum.map(fn m -> values_to_stringables(m) end)
      |> CSVParser.dump_to_iodata()
      |> :unicode.characters_to_binary(:utf8, {:utf16, :little})

    conn |> chunk(rows)

    conn
  end

  def index(conn, _params) do
    render(conn, :index, meta: Meta.report())
  end

  defp remove_module_value(row) do
    row |> Enum.filter(fn v -> v != ExtractionPoint.Meta end)
  end
end
