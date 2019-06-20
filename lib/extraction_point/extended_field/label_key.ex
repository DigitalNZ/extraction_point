defmodule ExtractionPoint.ExtendedField.LabelKey do
  def to_key(label), do: label |> String.downcase() |> String.replace(" ", "_")
end
