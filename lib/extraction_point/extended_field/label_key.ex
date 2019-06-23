defmodule ExtractionPoint.ExtendedField.LabelKey do
  def to_key(label), do: label |> Inflex.parameterize("_")
  def to_plural_key(label), do: label |> Inflex.pluralize() |> Inflex.parameterize("_")
end
