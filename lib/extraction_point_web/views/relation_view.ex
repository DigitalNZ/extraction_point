defmodule ExtractionPointWeb.RelationView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.RelationView

  def render("index.json", %{relations: relations, meta: meta}) do
    %{meta: meta, data: render_many(relations, RelationView, "relation.json")}
  end

  def render("show.json", %{relation: relation}) do
    %{data: render_one(relation, RelationView, "relation.json")}
  end

  def render("relation.json", %{relation: relation}) do
    relation
  end
end
