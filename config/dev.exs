use Mix.Config

# Configure your database
config :extraction_point, ExtractionPoint.Repo,
  # see docker-compose.yml
  username: "postgres",
  password: "",
  database: "extraction_point_dev",
  hostname: "db",
  port: 5432,
  pool_size: 10
