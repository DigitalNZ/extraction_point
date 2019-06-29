defmodule ExtractionPoint.ContentType do
  use Ecto.Schema

  alias ExtractionPoint.{ContentTypeFieldMapping, ExtendedField}

  schema "content_types" do
    field :class_name, :string
    many_to_many :extended_fields, ExtendedField, join_through: ContentTypeFieldMapping
  end
end
