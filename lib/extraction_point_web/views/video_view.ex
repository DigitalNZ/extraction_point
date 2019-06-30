defmodule ExtractionPointWeb.VideoView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.VideoView

  def render("index.json", %{videos: videos, meta: meta}) do
    %{meta: meta, data: render_many(videos, VideoView, "video.json")}
  end

  def render("show.json", %{video: video}) do
    %{data: render_one(video, VideoView, "video.json")}
  end

  def render("video.json", %{video: video}) do
    video
  end
end
