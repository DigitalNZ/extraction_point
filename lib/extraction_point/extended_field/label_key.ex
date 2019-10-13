defmodule ExtractionPoint.ExtendedField.LabelKey do
  def to_key(label) do
    label
    |> String.replace("(", " ")
    |> String.replace(")", " ")
    |> Inflex.parameterize("_")
  end
  def to_plural_key(label) do
    label
    |> Inflex.pluralize()
    |> Inflex.parameterize("_")
  end
end
