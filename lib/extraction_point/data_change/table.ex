defmodule ExtractionPoint.DataChange.Table do
  use Ecto.Migration

  import Ecto.Query
  import ExtractionPoint.ExtendedField.Parse

  alias ExtractionPoint.{ExtendedField, Repo}

  @compound_types ~w(autocomplete choice)

  def alter_tags(table_name) do
    execute("UPDATE #{table_name} SET tags = '{}' WHERE tags IS NULL")
    execute("ALTER TABLE #{table_name} ALTER COLUMN tags SET DEFAULT '{}'")
  end

  def add_columns_to_table_from_extended_fields(type, table_name) do
    alterations =
      Enum.reduce(
        type.extended_fields,
        [],
        fn ef, acc -> acc ++ ExtendedField.add_to_table_sql(ef, table_name) end
      )

    Enum.each(alterations, fn s -> execute(s) end)
  end

  # build updates from extended_content and load them
  # note: per row db update operation
  def load_data_to_new_columns_from_extended_content(type, table_name) do
    table_name
    |> query()
    |> Repo.all()
    |> Enum.each(fn row ->
      updates = build_updates(row, type)

      unless is_nil(updates) do
        # run updates per row
        from(t in table_name,
          update: [set: ^updates],
          where: t.id == ^row.id
        )
        |> Repo.update_all([])
      end
    end)
  end

  defp query(table_name) do
    from(t in table_name,
      select: %{
        id: t.id,
        extended_content: t.extended_content,
        # determine if has_any_multiples in all of extended_content
        has_any_multiples: fragment("extended_content LIKE '%_multiple%' as has_any_multiples")
      },
      where: not is_nil(t.extended_content)
    )
  end

  defp build_updates(row, type) do
    Enum.reduce(
      type.extended_fields,
      [],
      fn ef, acc ->
        ef = %{ef | compound_value: ef.ftype in @compound_types}

        acc ++
          extract_update_pair(ef, row.extended_content, row.has_any_multiples)
      end
    )
  end
end
