defmodule ExtractionPoint.Exporter do
  alias ExtractionPoint.Repo

  @table_name_prefix "extracted"

  def list_type(type) do
    query = "select * from #{to_table_name(type)} limit 3"

    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query, []) do
      columns = to_keys(results.columns)

      {columns, map_rows(columns, results.rows)}
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

  defp map_rows(columns, rows) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row)
      |> Map.new()
    end)
  end
end
