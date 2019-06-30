defmodule ExtractionPointWeb.StillImageView do
  use ExtractionPointWeb, :view
  alias ExtractionPointWeb.StillImageView

  def render("index.json", %{still_images: still_images, meta: meta}) do
    %{meta: meta, data: render_many(still_images, StillImageView, "still_image.json")}
  end

  def render("show.json", %{still_image: still_image}) do
    %{data: render_one(still_image, StillImageView, "still_image.json")}
  end

  def render("still_image.json", %{still_image: still_image}) do
    still_image
  end
end
