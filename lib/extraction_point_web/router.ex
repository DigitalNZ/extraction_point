defmodule ExtractionPointWeb.Router do
  use ExtractionPointWeb, :router

  pipeline :api do
    plug :accepts, ["json", "csv"]
  end

  scope "/", ExtractionPointWeb do
    pipe_through :api

    resources "/", MetaDataController, only: [:index]
    resources "/meta.csv", MetaDataController, only: [:index]
    resources "/web-links", WebLinkController, only: [:show, :index]
    resources "/web-links.csv", WebLinkController, only: [:index]
  end
end
