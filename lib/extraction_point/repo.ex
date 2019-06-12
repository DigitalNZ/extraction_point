defmodule ExtractionPoint.Repo do
  use Ecto.Repo,
    otp_app: :extraction_point,
    adapter: Ecto.Adapters.Postgres
end
