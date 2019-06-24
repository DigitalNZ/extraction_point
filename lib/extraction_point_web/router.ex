defmodule ExtractionPointWeb.Router do
  use ExtractionPointWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ExtractionPointWeb do
    pipe_through :api
  end
end
