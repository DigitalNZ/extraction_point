defmodule ExtractionPoint.ExtendedField.LabelKey do
  def to_key(label) do
    label
    |> clean()
    |> Inflex.parameterize("_")
  end

  def to_plural_key(label) do
    label
    |> clean()
    |> Inflex.pluralize()
    |> Inflex.parameterize("_")
  end

  defp clean(label) do
    label
    |> String.replace("(", " ")
    |> String.replace(")", " ")
    |> String.trim()
  end
end
