defmodule ExtractionPoint.ExportUtils do
  @table_name_prefix "extracted"

  def prefix(), do: @table_name_prefix

  def map_rows(columns, rows) do
    Enum.map(rows, fn row ->
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
end
