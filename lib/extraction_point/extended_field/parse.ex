defmodule ExtractionPoint.ExtendedField.Parse do
  import SweetXml
  import ExtractionPoint.ExtendedField.LabelKey

  alias ExtractionPoint.ExtendedField

  @boolean_types ~w(checkbox radio)
  @simple_types ~w(text textarea date)
  @choice_types ~w(autocomplete choice)

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

  # last parameter is "has_any_multiples" for extended content
  # if false, we can use xpath because extended_content should be valid xml
  # if true, we have to extract substring of xml before using xpath
  def extract_update_pair(%ExtendedField{ftype: ft, label: l}, extended_content, false)
      when ft in @boolean_types do
    {col, value} = simple_xml_parse(l, extended_content)

    [{col, resolve_to_boolean(value)}]
  end

  # booleans can never be a multiple
  def extract_update_pair(%ExtendedField{ftype: ft, label: l}, extended_content, true)
      when ft in @boolean_types do
    {label_key, col} = key_and_col(l)
    doc = sub_xml_for_key(extended_content, label_key)
    value = fetch_value(doc, label_key) |> resolve_to_boolean()

    [{col, value}]
  end

  def extract_update_pair(%ExtendedField{ftype: ft, label: l}, extended_content, false) when ft in @simple_types do
    {col, value} = simple_xml_parse(l, extended_content)

    [{col, value}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: ft, label: l, multiple: false},
        extended_content,
        true
      ) when ft in @simple_types do
    {label_key, col} = key_and_col(l)
    doc = sub_xml_for_key(extended_content, label_key)

    [{col, fetch_value(doc, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: ft, label: l, multiple: true},
        extended_content,
        _
      )
      when ft in @simple_types do
    {label_key, col} = l |> key_and_col()

    values =
      extended_content
      |> sub_xml_for_multiple_key(label_key)
      |> fetch_multiple_values(label_key, 1, [])

    case values do
      [] -> [{col, nil}]
      [nil] -> [{col, nil}]
      [_] -> [{col, values}]
    end
  end

  def extract_update_pair(%ExtendedField{ftype: "year", label: l}, extended_content, false) do
    {label_key, col} = key_and_col(l)

    [{col, fetch_year_value(extended_content, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "year", label: l, multiple: false},
        extended_content,
        true
      ) do
    {label_key, col} = key_and_col(l)

    doc = sub_xml_for_key(extended_content, label_key)

    [{col, fetch_year_value(doc, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "year", label: l, multiple: true},
        extended_content,
        _
      ) do
    {label_key, col} = key_and_col(l)

    values =
      extended_content
      |> sub_xml_for_multiple_key(label_key)
      |> fetch_multiple_values(label_key, 1, [], &fetch_year_value/2)

    [{col, values}]
  end

  # ftype is either topic_type or choice type
  def extract_update_pair(
        %ExtendedField{ftype: "topic_type", label: l},
        extended_content,
        false
      ) do
    {label_key, col} = key_and_col(l)

    [{col, fetch_topic_type_value(extended_content, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "topic_type", label: l, multiple: false},
        extended_content,
        true
      ) do
    {label_key, col} = key_and_col(l)

    doc = sub_xml_for_key(extended_content, label_key)

    [{col, fetch_topic_type_value(doc, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "topic_type", label: l, multiple: true},
        extended_content,
        _
      ) do
    {label_key, col} = l |> key_and_col()

    values =
      extended_content
      |> sub_xml_for_multiple_key(label_key)
      |> fetch_multiple_values(label_key, 1, [], &fetch_topic_type_value/2)

    [{col, values}]
  end

  # choice types themselves have the invalid xml number based elements
  # so always has_any_multiples should be true for them, but...
  # if extended_content doesn't have even an empty value for the choice field
  # has_any_multiples may be false
  def extract_update_pair(
        %ExtendedField{ftype: ft, label: l, multiple: false},
        extended_content,
        _
  )
  when ft in @choice_types do
    {label_key, col} = key_and_col(l)

    string = sub_xml_for_key(extended_content, label_key)

    [{col, fetch_choice_labelled_value_map(string, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: ft, label: l, multiple: true},
        extended_content,
        _
  )
    when ft in @choice_types do
    {label_key, col} = l |> key_and_col()

    values =
      extended_content
      |> sub_xml_for_multiple_key(label_key)
      |> fetch_multiple_values(label_key, 1, [], &fetch_choice_labelled_value_map/2)

    [{col, values}]
  end

  def extract_update_pair(%ExtendedField{ftype: "map", label: l}, extended_content, false) do
    {label_key, col} = key_and_col(l)

    [{col, fetch_map_value(extended_content, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "map", label: l, multiple: false},
        extended_content,
        true
      ) do
    {label_key, col} = key_and_col(l)

    doc = sub_xml_for_key(extended_content, label_key)

    [{col, fetch_map_value(doc, label_key)}]
  end

  def extract_update_pair(
        %ExtendedField{ftype: "map", label: l, multiple: true},
        extended_content,
        _
      ) do
    {label_key, col} = l |> key_and_col()

    values =
      extended_content
      |> sub_xml_for_multiple_key(label_key)
      |> fetch_multiple_values(label_key, 1, [], &fetch_map_value/2)

    [{col, values}]
  end

  def extract_update_pair(%ExtendedField{ftype: "map_address", label: l}, extended_content, false) do
    key_stub = to_key(l)
    key_coordinates = "#{key_stub}_coordinates"
    key_address = "#{key_stub}_address"

    coordinates = fetch_map_value(extended_content, key_stub)
    address = fetch_address_value(extended_content, key_stub) |> populated_string_or_nil()

    if not is_nil(coordinates) or not is_nil(address) do
      [
        {String.to_atom(key_coordinates), coordinates},
        {String.to_atom(key_address), address}
      ]
    end
  end

  def extract_update_pair(
        %ExtendedField{ftype: "map_address", label: l, multiple: false},
        extended_content,
        true
      ) do
    key_stub = to_key(l)
    key_coordinates = "#{key_stub}_coordinates"
    key_address = "#{key_stub}_address"

    doc = sub_xml_for_key(extended_content, key_stub)
    coordinates = fetch_map_value(doc, key_stub)
    address = fetch_address_value(doc, key_stub) |> populated_string_or_nil()

    if not is_nil(coordinates) or not is_nil(address) do
      [
        {String.to_atom(key_coordinates), coordinates},
        {String.to_atom(key_address), address}
      ]
    end
  end

  def extract_update_pair(
        %ExtendedField{ftype: "map_address", label: l, multiple: true},
        extended_content,
        _
      ) do
    key_stub = to_key(l)
    key_coordinates = "#{key_stub}_coordinates"
    key_address = "#{key_stub}_addresses"

    doc = extended_content |> sub_xml_for_multiple_key(key_stub)
    coordinates_values = doc |> fetch_multiple_values(key_stub, 1, [], &fetch_map_value/2)
    address_values = doc |> fetch_multiple_values(key_stub, 1, [], &fetch_address_value/2)

    [
      {String.to_atom(key_coordinates), coordinates_values},
      {String.to_atom(key_address), address_values}
    ]
  end

  defp fetch_multiple_values(string, key, n, acc, extractor \\ &fetch_value/2)
  defp fetch_multiple_values(nil, _, _, acc, _), do: acc
  defp fetch_multiple_values(string, key, n, acc, extractor) do
    if String.contains?(string, "<#{n}>") do
      xml = Regex.run(~r/<#{n}[^>]*>(.*)<\/#{n}>/, string) |> List.last()

      fetch_multiple_values(string, key, n + 1, acc ++ [extractor.(xml, key)])
    else
      acc
    end
  end

  defp key_and_col(label) do
    key = label |> to_key()
    col = String.to_atom(key)

    {key, col}
  end

  defp fetch_value(nil, _), do: nil
  defp fetch_value(xml, key), do: xml |> resolved_xpath(~x"/#{key}/text()")

  defp fetch_labelled_value(nil, _), do: {nil, nil}
  defp fetch_labelled_value(xml, key) do
    label = xml |> resolved_xpath(~x"/#{key}/@label")
    value = xml |> resolved_xpath(~x"/#{key}/text()")

    {label, value}
  end

  defp fetch_choice_labelled_value_map(string, key, number \\ 1)
  defp fetch_choice_labelled_value_map(nil, _, _), do: nil
  defp fetch_choice_labelled_value_map(string, key, number) do
    {label, value} = extract_choice_label_value(string, key, number)

    case {label, value} do
      {nil, nil} -> nil
      _ -> %{label: label, value: value}
    end
  end

  defp extract_choice_label_value(nil, _, _), do: nil
  defp extract_choice_label_value(string, key, number) do
    results = Regex.run(~r/<#{key}[^>]*><#{number} label=\"([^\"]*)\">([^>]*)<\/#{number}><\/#{key}>/, string)

    if Enum.any?(results) do
      {Enum.at(results, 1), Enum.at(results, 2)}
    else
      nil
    end
  end

  defp fetch_map_value(nil, _), do: nil
  defp fetch_map_value(xml, key) do
    with {:ok, string} <- coordinates_as_string(xml, key),
         {:ok, coordinates} <- format_coordinates(string) do
      %Geo.Point{coordinates: coordinates, srid: 4326}
    end
  end

  defp format_coordinates(string) do
    coordinates =
      string
      |> String.split(",")
      |> Enum.map(&String.to_float/1)
      |> List.to_tuple()

    {:ok, coordinates}
  end

  defp coordinates_as_string(xml, key) do
    coordinates = xml |> resolved_xpath(~x"/#{key}/coords/text()")

    if not is_nil(coordinates) and byte_size(coordinates) != 0 do
      {:ok, coordinates}
    end
  end

  defp fetch_address_value(nil, _), do: nil
  defp fetch_address_value(xml, key), do: xml |> resolved_xpath(~x"/#{key}/address/text()")

  defp fetch_topic_type_value(nil, _), do: nil
  defp fetch_topic_type_value(xml, key) do
    {topic_label, url} = fetch_labelled_value(xml, key)

    case {topic_label, url} do
      {nil, nil} -> nil
      _ -> %{label: topic_label, url: url}
    end
  end

  def fetch_year_value(nil, _), do: nil
  def fetch_year_value(xml, key) do
    circa = xml |> resolved_xpath(~x"/#{key}/circa/text()")
    value = xml |> resolved_xpath(~x"/#{key}/value/text()")

    if circa do
      if circa == '1' do
        "circa #{value}"
      else
        value
      end
    else
      xml |> resolved_xpath(~x"/#{key}/text()")
    end
  end

  defp simple_xml_parse(label, xml) do
    {key, col} = key_and_col(label)

    {col, fetch_value(xml, key)}
  end

  defp resolve_to_boolean("yes"), do: true
  defp resolve_to_boolean(_), do: false

  # since some other extended field is a multiple, we can't xml parse overall extended_content
  # as it invalid xml, get substring for field first
  defp sub_xml_for_key(string, key) do
    matches = Regex.run(~r/<#{key}[^>]*>.*<\/#{key}>/, string)

    if matches, do: matches |> List.last()
  end

  defp sub_xml_for_multiple_key(string, key) do
    matches = Regex.run(~r/<#{key}_multiple[^>]*>(.*)<\/#{key}_multiple>/, string)

    if matches, do: matches |> List.last()
  end

  defp populated_string_or_nil(""), do: nil
  defp populated_string_or_nil(string), do: string

  # make sure xpath returns nil or string
  defp resolved_xpath(xml, pattern) do
    result = xpath(xml, pattern)

    case result do
      nil -> nil
      _ -> result |> to_string()
    end
  end
end
