defmodule ExtractionPoint.CSVUtils do
  def values_to_stringables(row) do
    row |> Enum.map(fn v ->
      case v do
        %NaiveDateTime{} -> v |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()
        value when is_map(value) or is_list(value) -> value |> inspect([charlists: :as_lists])
        _ -> v
      end
    end)
  end
end
