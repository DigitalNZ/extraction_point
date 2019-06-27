defmodule ExtractionPoint.Repo.Migrations.AddIdPathSegmentToFileFunction do
  use Ecto.Migration

  @create_function ~s"""
  CREATE OR REPLACE FUNCTION id_path_segment_to_file(integer, text) returns text as
  $$ select concat(array_to_string(regexp_split_to_array(lpad($1::text, 12, '0'), E'(?=(....)+$)'), '/'), '/', $2);
  $$ LANGUAGE sql IMMUTABLE;
  """
  @drop_function ~s"""
  DROP FUNCTION IF EXISTS id_path_segment_to_file(integer, text)
  """
  def change do
    execute(@create_function, @drop_function)
  end
end
