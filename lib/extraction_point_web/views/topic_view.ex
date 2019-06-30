defmodule ExtractionPointWeb.TopicView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.TopicView

  def render("index.json", %{topics: topics, meta: meta}) do
    %{meta: meta, data: render_many(topics, TopicView, "topic.json")}
  end

  def render("show.json", %{topic: topic}) do
    %{data: render_one(topic, TopicView, "topic.json")}
  end

  def render("topic.json", %{topic: topic}) do
    topic
  end
end
