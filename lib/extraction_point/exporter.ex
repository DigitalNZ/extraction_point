defmodule ExtractionPoint.Exporter do
  alias ExtractionPoint.Repo

  @table_name_prefix "extracted"

  # assume pagination rather than stream for json, etc.
  def list_type(type) do
    query = "select * from #{to_table_name(type)}"

    # we do a separate query before batch stream so as to get columns dynamically
    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query, []) do
      columns = to_keys(results.columns)

      {columns, map_rows(columns, results.rows)}
    end
  end

  def list_type(type, process_stream) do
    query = "select * from #{to_table_name(type)}"
    query_for_columns = "#{query} limit 1"

    # we do a separate query before batch stream so as to get columns dynamically
    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query_for_columns, []) do
      columns = results.columns

      {columns, as_stream(query, fn stream -> process_stream.(columns, stream) end)}
    end
  end

  def get_type(type, id) do
    query = "select * from #{to_table_name(type)} where id = #{id}"

    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query, []) do
      columns = to_keys(results.columns)
      row = columns
      |> map_rows(results.rows)
      |> List.last()

      {columns, row}
    end
  end

  def map_rows(columns, rows) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row)
      |> Map.new()
    end)
  end

  defp to_table_name(type) do
    type
    |> to_string()
    |> Inflex.pluralize()
    |> List.wrap()
    |> Enum.concat([@table_name_prefix])
    |> Enum.reverse()
    |> Enum.join("_")
  end

  defp to_keys(columns) do
    Enum.map(columns, fn c -> String.to_atom(c) end)
  end

  defp as_stream(query, callback) do
    Repo.transaction(fn ->
      stream = Ecto.Adapters.SQL.stream(Repo, query, [])
      callback.(stream)
    end)
  end
end
