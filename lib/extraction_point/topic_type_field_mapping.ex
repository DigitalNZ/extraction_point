defmodule ExtractionPoint.TopicTypeFieldMapping do
  use Ecto.Schema

  schema "topic_type_to_field_mappings" do
    belongs_to :topic_type, ExtractionPoint.TopicType
    belongs_to :extended_field, ExtractionPoint.ExtendedField
  end
end
