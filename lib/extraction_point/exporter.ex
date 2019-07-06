defmodule ExtractionPoint.Exporter do
  import ExtractionPoint.ExportUtils

  alias ExtractionPoint.Repo

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
    stripped_options = options |> Map.delete("limit") |> Map.delete("offset")

    query_for_columns =
      raw_sql(type, stripped_options)
      |> add_to_sql_if_present(%{"limit" => 1}, "limit")

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

      row =
        columns
        |> map_rows(results.rows)
        |> List.last()

      {columns, row}
    end
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

  defp raw_sql(type, %{"except_baskets" => except_baskets} = options) do
    except_baskets = except_baskets |> String.split(",")

    sql = ~s"""
    #{select_all_from(type)}
    WHERE basket_key NOT IN (#{basket_list_as_string(except_baskets)})
    ORDER BY id
    """

    sql
    |> add_to_sql_if_present(options, "limit")
    |> add_to_sql_if_present(options, "offset")
  end

  defp raw_sql(type, %{"only_baskets" => only_baskets} = options) do
    only_baskets = only_baskets |> String.split(",")

    sql = ~s"""
    #{select_all_from(type)}
    WHERE basket_key IN (#{basket_list_as_string(only_baskets)})
    ORDER BY id
    """

    sql
    |> add_to_sql_if_present(options, "limit")
    |> add_to_sql_if_present(options, "offset")
  end

  defp raw_sql(type, %{"topic_type" => _}) do
    "#{select_all_from(type)} ORDER BY id"
  end

  defp select_all_from(type) do
    "SELECT * FROM #{to_table_name(type)}"
  end

  defp basket_list_as_string(baskets) do
    baskets
    |> Enum.map(fn b -> "'#{b}'" end)
    |> Enum.join(",")
  end

  # values are only intended to be integers
  # adding rudimentary sql injection protection
  # (even though this isn't meant to be public facing app)
  # which will throw error if non integer submitted
  defp add_to_sql_if_present(sql, options, key) do
    case Map.get(options, key) do
      nil -> sql
      value when is_integer(value) -> "#{sql} #{String.upcase(key)} #{value}"
      value -> "#{sql} #{String.upcase(key)} #{String.to_integer(value)}"
    end
  end
end
