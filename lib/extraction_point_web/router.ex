defmodule ExtractionPointWeb.Router do
  use ExtractionPointWeb, :router

  pipeline :api do
    plug :accepts, ["json", "csv"]
  end

  scope "/", ExtractionPointWeb do
    pipe_through :api

    resources "/", MetaDataController, only: [:index]
    resources "/meta.csv", MetaDataController, only: [:index]
    resources "/audio-recordings", AudioRecordingController, only: [:show, :index]
    resources "/audio-recordings.csv", AudioRecordingController, only: [:index]
    resources "/documents", DocumentController, only: [:show, :index]
    resources "/documents.csv", DocumentController, only: [:index]
    resources "/still-images", StillImageController, only: [:show, :index]
    resources "/still-images.csv", StillImageController, only: [:index]
    resources "/users", UserController, only: [:show, :index]
    resources "/users.csv", UserController, only: [:index]
    resources "/videos", VideoController, only: [:show, :index]
    resources "/videos.csv", VideoController, only: [:index]
    resources "/web-links", WebLinkController, only: [:show, :index]
    resources "/web-links.csv", WebLinkController, only: [:index]
  end
end
