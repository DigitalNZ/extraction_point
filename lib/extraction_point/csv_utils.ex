defmodule ExtractionPoint.CSVUtils do
  def values_to_stringables(row) do
    row |> Enum.map(fn v ->
      case v do
        value when is_map(value) or is_list(value) -> value |> inspect()
        _ -> v
      end
    end)
  end
end
