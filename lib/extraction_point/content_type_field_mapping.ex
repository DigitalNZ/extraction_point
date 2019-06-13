defmodule ExtractionPoint.ContentTypeFieldMapping do
  use Ecto.Schema

  import Ecto.Query

  schema "content_type_to_field_mappings" do
    belongs_to :content_type, ExtractionPoint.ContentType
    belongs_to :extended_field, ExtractionPoint.ExtendedField
  end
end
