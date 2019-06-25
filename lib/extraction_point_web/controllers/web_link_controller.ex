defmodule ExtractionPointWeb.WebLinkController do
  use ExtractionPointWeb, :controller

  alias ExtractionPoint.Exporter

  action_fallback ExtractionPointWeb.FallbackController

  def index(conn, _params) do
    {columns, web_links} = Exporter.list_type(:web_link)

    render(conn, :index, columns: columns, web_links: web_links)
  end

  def show(conn, %{"id" => id}) do
    {columns, web_link} = Exporter.get_type(:web_link, id)

    render(conn, :show, columns: columns, web_link: web_link)
  end
end
