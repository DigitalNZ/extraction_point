defmodule ExtractionPointWeb.MetaDataView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.MetaDataView

  def render("index.json", %{meta: meta}) do
    %{data: render_many(meta, MetaDataView, "meta.json")}
  end

  def render("meta.json", %{meta_data: meta_data}) do
    meta_data
  end
end
