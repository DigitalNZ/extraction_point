defmodule ExtractionPoint.ExportUtils do
  @table_name_prefix "extracted"

  def prefix(), do: @table_name_prefix

  def map_rows(columns, rows) do
    Enum.map(rows, fn row ->
      row = resolve_values(row)

      Enum.zip(columns, row)
      |> Map.new()
    end)
  end

  def to_table_name(type) do
    type
    |> to_string()
    |> Inflex.pluralize()
    |> List.wrap()
    |> Enum.concat([@table_name_prefix])
    |> Enum.reverse()
    |> Enum.join("_")
  end

  def to_keys(columns) do
    Enum.map(columns, fn c -> String.to_atom(c) end)
  end

  defp resolve_values(row) do
    Enum.map(row, fn value ->
      modify_value_if_necessary(value)
    end)
  end

  defp modify_value_if_necessary(value) do
    case value do
      %NaiveDateTime{} -> value |> NaiveDateTime.truncate(:second)
      _ -> value
    end
  end
end
