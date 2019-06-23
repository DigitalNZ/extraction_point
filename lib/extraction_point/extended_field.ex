defmodule ExtractionPoint.ExtendedField do
  use Ecto.Schema

  import ExtractionPoint.ExtendedField.LabelKey

  @boolean_types ~w(checkbox radio)
  @text_types ~w(text textarea year)
  @choice_types ~w(autocomplete choice)

  schema "extended_fields" do
    field(:label, :string)
    field(:ftype, :string)
    field(:multiple, :boolean)
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
  def add_to_table_sql(%__MODULE__{ftype: ft, label: l}, table_name) when ft in @boolean_types do
    [alter_table_statement(table_name, l, "boolean")]
  end

  def add_to_table_sql(%__MODULE__{ftype: ft, label: l, multiple: false}, table_name)
      when ft in @text_types do
    [alter_table_statement(table_name, l, "text")]
  end

  def add_to_table_sql(%__MODULE__{ftype: ft, label: l, multiple: true}, table_name)
      when ft in @text_types do
    [alter_table_statement(table_name, l, "text[]")]
  end

  def add_to_table_sql(
        %__MODULE__{ftype: ft, label: l, multiple: false},
        table_name
      )
      when ft in @choice_types do
    [alter_table_statement(table_name, l, "jsonb")]
  end

  def add_to_table_sql(
        %__MODULE__{ftype: ft, label: l, multiple: true},
        table_name
      )
      when ft in @choice_types do
    [alter_table_statement(table_name, l, "jsonb[]")]
  end

  def add_to_table_sql(%__MODULE__{ftype: ft, label: l, multiple: false}, table_name)
      when ft in @choice_types do
    [alter_table_statement(table_name, l, "text")]
  end

  def add_to_table_sql(%__MODULE__{ftype: ft, label: l, multiple: true}, table_name)
      when ft in @choice_types do
    [alter_table_statement(table_name, l, "text[]")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "date", label: l, multiple: false}, table_name) do
    [alter_table_statement(table_name, l, "date")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "date", label: l, multiple: true}, table_name) do
    [alter_table_statement(table_name, l, "date[]")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "topic_type", label: l, multiple: false}, table_name) do
    [alter_table_statement(table_name, l, "jsonb")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "topic_type", label: l, multiple: true}, table_name) do
    [alter_table_statement(table_name, l, "jsonb[]")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "map", label: l, multiple: false}, table_name) do
    # this constrains the format to "standard GPS" (epsg4326) e.g. coordinate pair {longitude,latitude}
    ["SELECT AddGeometryColumn ('#{table_name}','#{l}',4326,'POINT',2)"]
  end

  # in order to add multiple of geo, we don't constrain it to specific format here
  def add_to_table_sql(%__MODULE__{ftype: "map", label: l, multiple: true}, table_name) do
    [alter_table_statement(table_name, l, "geometry(Point, 4326))[]")]
  end

  def add_to_table_sql(%__MODULE__{ftype: "map_address", label: l, multiple: false}, table_name) do
    # this constrains the format to "standard GPS" (epsg4326) e.g. coordinate pair {longitude,latitude}
    coordinates_statement =
      "SELECT AddGeometryColumn ('#{table_name}','#{to_key(l)}_coordinates',4326,'POINT',2)"

    address_statement = alter_table_statement(table_name, "#{to_key(l)}_address", "text")

    [coordinates_statement, address_statement]
  end

  # in order to add multiple of geo, we don't constrain it to specific format here
  def add_to_table_sql(%__MODULE__{ftype: "map_address", label: l, multiple: true}, table_name) do
    [
      alter_table_statement(table_name, "#{to_key(l)}_coordinates", "geometry[]"),
      alter_table_statement(table_name, "#{to_key(l)}_address", "text[]")
    ]
  end

  defp alter_table_statement(table_name, label, type) do
    "ALTER TABLE #{table_name} ADD COLUMN #{to_key(label)} #{type}"
  end
end
