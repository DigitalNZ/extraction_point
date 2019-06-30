defmodule ExtractionPointWeb.DocumentView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.DocumentView

  def render("index.json", %{documents: documents, meta: meta}) do
    %{meta: meta, data: render_many(documents, DocumentView, "document.json")}
  end

  def render("show.json", %{document: document}) do
    %{data: render_one(document, DocumentView, "document.json")}
  end

  def render("document.json", %{document: document}) do
    document
  end
end
