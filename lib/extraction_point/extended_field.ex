defmodule ExtractionPoint.ExtendedField do
  use Ecto.Schema

  schema "extended_fields" do
    field :label, :string
    field :ftype, :string
    field :multiple, :boolean
  end
end
