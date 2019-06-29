defmodule ExtractionPointWeb.WebLinkView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.WebLinkView

  def render("index.json", %{web_links: web_links, meta: meta}) do
    %{meta: meta, data: render_many(web_links, WebLinkView, "web_link.json")}
  end

  def render("show.json", %{web_link: web_link}) do
    %{data: render_one(web_link, WebLinkView, "web_link.json")}
  end

  def render("web_link.json", %{web_link: web_link}) do
    web_link
  end
end
