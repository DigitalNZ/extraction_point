# need to break down raw_sql into select, from, where, and finishing clauses
# since ecto version isn't ready for primetime, maybe do hardcoded version for tauranga
# in builder for include_related, have count to assign table name alias
# use it for select for outside
defmodule ExtractionPoint.Exporter do
  import Ecto.Query
  import ExtractionPoint.ExportUtils

  alias ExtractionPoint.Repo

  @not_public_title "No Public Version Available  (perhaps this item is under construction?)"

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

  defp build_baskets_where_clause(table_prefix, %{"except_baskets" => except_baskets}) do
    except_baskets = except_baskets |> String.split(",")

    "#{table_prefix}basket_key NOT IN (#{basket_list_as_string(except_baskets)})"
  end

  defp build_baskets_where_clause(table_prefix, %{"only_baskets" => only_baskets}) do
    only_baskets = only_baskets |> String.split(",")

    "#{table_prefix}basket_key IN (#{basket_list_as_string(only_baskets)})"
  end

  defp build_baskets_where_clause(_, _), do: nil

  defp raw_basket_sql(type, options) do
    sql = ~s"""
    #{select_all_from(type)}
    WHERE #{build_baskets_where_clause("", options)}
    ORDER BY id
    """

    sql
    |> add_to_sql_if_present(options, "limit")
    |> add_to_sql_if_present(options, "offset")
  end

  defp raw_sql(type, options) when options == %{} do
    "#{select_all_from(type)} ORDER BY id"
  end

  defp raw_sql(type, %{"include_related" => include_related} = options) when not is_nil(include_related) do
    type_as_table = to_table_name(type)
    type_table_prefix = "target"

    # create map of tables to prefixes
    # create relations subquery name prefix for each iteration
    # accumulate query parts in lists per related table
    # select has ids and titles columns per related table
    # and target all columns wildcard once
    parts = related_tables(type_as_table)
    |> Enum.with_index()
    |> Enum.reduce(%{selects: [], joins: []}, fn related_meta, acc ->
      {related_table, index} = related_meta

      ids_column = "#{related_table}_ids"
      titles_column = "#{related_table}_titles"

      agg_args = %{related_ids_and_titles_subquery: related_ids_and_titles_subquery(related_table, index, type_as_table),
                   index: index,
                   type_as_table: type_as_table,
                   ids_column: ids_column,
                   titles_column: titles_column}

      aggsubt = "aggsubt#{index}"

      select_clause = ~s"""
      #{aggsubt}.#{ids_column},
      #{aggsubt}.#{titles_column}
      """

      join_clause = ~s"""
      FULL JOIN (#{aggregate_subqquery(agg_args)}) #{aggsubt}
      ON #{type_table_prefix}.id = #{aggsubt}.id
      """

      %{selects: acc.selects ++ [select_clause], joins: acc.joins ++ [join_clause]}
    end)

    sql = ~s"""
    SELECT #{type_table_prefix}.*,
    #{Enum.join(parts.selects, ",\n")}
    FROM #{type_as_table} #{type_table_prefix}
    #{Enum.join(parts.joins, "\n")}
    """

    # add basket where clause if necessary
    sql = case build_baskets_where_clause("#{type_table_prefix}.", options) do
            nil -> sql
            value -> "#{sql} WHERE #{value}"
          end

    sql = "#{sql} ORDER BY #{type_table_prefix}.id"

    sql = sql
    |> add_to_sql_if_present(options, "limit")
    |> add_to_sql_if_present(options, "offset")

    File.write("full.sql", sql)

    sql
  end

  defp raw_sql(type, %{"except_baskets" => _} = options), do: raw_basket_sql(type, options)
  defp raw_sql(type, %{"only_baskets" => _} = options), do: raw_basket_sql(type, options)

  defp raw_sql(type, %{} = options) do
    sql = "#{select_all_from(type)} ORDER BY id"

    sql
    |> add_to_sql_if_present(options, "limit")
    |> add_to_sql_if_present(options, "offset")
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

  defp related_tables(type_as_table) do
    from(
      rt in "extracted_relations",
      distinct: true,
      select: rt.related_item_table,
      where: rt.source_table == ^type_as_table
    ) |> Repo.all()
  end

  defp related_ids_and_titles_subquery(related_table, index, type_as_table) do
    rit = "ri#{index}"
    relst = "r#{index}"

    ~s"""
    SELECT #{rit}.id, #{rit}.title, #{relst}.source_id
    FROM #{related_table} #{rit}
    JOIN extracted_relations #{relst}
    ON #{relst}.related_item_id = #{rit}.id
    WHERE #{relst}.source_table = '#{type_as_table}'
    AND related_item_table = '#{related_table}'
    AND #{rit}.title != '#{@not_public_title}'
    """
  end

  defp aggregate_subqquery(args) do
    aggt = "aggt#{args.index}"
    risubt = "risubt#{args.index}"

    ~s"""
    SELECT #{aggt}.id,
    ARRAY_AGG(#{risubt}.id) AS #{args.ids_column},
    ARRAY_AGG(#{risubt}.title) AS #{args.titles_column}
    FROM #{args.type_as_table} #{aggt}
    JOIN (#{args.related_ids_and_titles_subquery}) #{risubt}
    ON #{risubt}.source_id = #{aggt}.id
    GROUP BY #{aggt}.id
    """
  end
end
