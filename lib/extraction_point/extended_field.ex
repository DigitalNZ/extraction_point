defmodule ExtractionPoint.ExtendedField do
  use Ecto.Schema

  @boolean_types ~w(checkbox radio)
  @text_types ~w(text textarea year autocomplete choice)

  schema "extended_fields" do
    field :label, :string
    field :ftype, :string
    field :multiple, :boolean
  end

  # possible ftypes:
  # * checkbox
  # * radio
  # * date
  # * year
  # * text
  # * textarea
  # * autocomplete
  # * choice
  # # topic_type
  # * map
  # * map_address


  # returns list (usually only with one element)
  # ftype map_address is special case where it will return two elements
  # def add_to_table_sql(%__MODULE__{ftype: "map_address", multiple: false} = extended_field, table_name) do
  # year can have circa value, so making text field rather than locking to 4 chars
  # multiple not allowed for checkbox or radio
  def add_to_table_sql(%__MODULE__{ftype: ftype, label: label}, table_name) when ftype in @boolean_types do
    [alter_table_statement(table_name, label, "boolean")]
  end
  def add_to_table_sql(%__MODULE__{ftype: ftype, label: label, multiple: false}, table_name) when ftype in @text_types do
    [alter_table_statement(table_name, label, "text")]
  end
  def add_to_table_sql(%__MODULE__{ftype: ftype, label: label, multiple: true}, table_name) when ftype in @text_types do
    [alter_table_statement(table_name, label, "text[]")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "date", label: label, multiple: false}, table_name) do
    [alter_table_statement(table_name, label, "date")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "date", label: label, multiple: true}, table_name) do
    [alter_table_statement(table_name, label, "date[]")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "topic_type", label: label, multiple: false}, table_name) do
    [alter_table_statement(table_name, label, "jsonb")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "topic_type", label: label, multiple: true}, table_name) do
    [alter_table_statement(table_name, label, "jsonb[]")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "map", label: label, multiple: false}, table_name) do
    # this constrains the format to "standard GPS" (epsg4326) e.g. coordinate pair {longitude,latitude}
    ["SELECT AddGeometryColumn ('#{table_name}','#{label}',4326,'POINT',2)"]
  end
  # in order to add multiple of geo, we don't constrain it to specific format here
  def add_to_table_sql(%__MODULE__{ftype: "map", label: label, multiple: true}, table_name) do
    [alter_table_statement(table_name, label, "geometry(Point, 4326))[]")]
  end
  def add_to_table_sql(%__MODULE__{ftype: "map_address", label: label, multiple: false}, table_name) do
    # this constrains the format to "standard GPS" (epsg4326) e.g. coordinate pair {longitude,latitude}
    coordinates_statement = "SELECT AddGeometryColumn ('#{table_name}','#{String.downcase(label)}_coordinates',4326,'POINT',2)"
    address_statement = alter_table_statement(table_name, "#{String.downcase(label)}_address", "text")

    [coordinates_statement, address_statement]
  end
  # in order to add multiple of geo, we don't constrain it to specific format here
  def add_to_table_sql(%__MODULE__{ftype: "map_address", label: label, multiple: true}, table_name) do
    [alter_table_statement(table_name, "#{String.downcase(label)}_coordinates", "geometry[]"),
     alter_table_statement(table_name, "#{String.downcase(label)}_address", "text[]")]
  end

  defp alter_table_statement(table_name, label, type) do
    "ALTER TABLE #{table_name} ADD COLUMN #{String.downcase(label)} #{type}"
  end
end
