defmodule ExtractionPoint.TopicType do
  use Ecto.Schema
  use Arbor.Tree

  alias ExtractionPoint.{TopicTypeFieldMapping, ExtendedField}

  schema "topic_types" do
    field :name, :string
    belongs_to :parent, __MODULE__
    many_to_many :extended_fields, ExtendedField, join_through: TopicTypeFieldMapping
  end
end
