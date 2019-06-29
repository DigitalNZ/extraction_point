defmodule ExtractionPoint.Exporter do
  alias ExtractionPoint.Repo

  @table_name_prefix "extracted"

  # assume pagination rather than stream for json, etc.
  def list_type(type, options \\ %{}) do
    query = raw_sql(type, options)

    # we do a separate query before batch stream so as to get columns dynamically
    with {:ok, results} <- Ecto.Adapters.SQL.query(Repo, query, []) do
      columns = to_keys(results.columns)

      {columns, map_rows(columns, results.rows)}
    end
  end

  def list_type(type, options, process_stream) do
    query = raw_sql(type, options)
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

  # max_rows: 500 by default
  defp as_stream(query, callback) do
    Repo.transaction(fn ->
      stream = Ecto.Adapters.SQL.stream(Repo, query, [])
      callback.(stream)
    end)
  end

  defp raw_sql(type, options) when options == %{} do
    "#{select_all_from(type)} ORDER BY id"
  end
  defp raw_sql(type, %{"except_baskets" => except_baskets}) do
    except_baskets = except_baskets |> String.split(",")
    ~s"""
    #{select_all_from(type)}
    WHERE basket_key NOT IN (#{basket_list_as_string(except_baskets)})
    ORDER BY id
    """
  end
  defp raw_sql(type, %{"only_baskets" => only_baskets}) do
    only_baskets = only_baskets |> String.split(",")
    ~s"""
    #{select_all_from(type)}
    WHERE basket_key IN (#{basket_list_as_string(only_baskets)})
    ORDER BY id
    """
  end

  defp select_all_from(type) do
    "SELECT * FROM #{to_table_name(type)}"
  end

  defp basket_list_as_string(baskets) do
    baskets
    |> Enum.map(fn b -> "'#{b}'"end)
    |> Enum.join(",")
  end
end
