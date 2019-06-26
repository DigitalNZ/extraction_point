defmodule ExtractionPoint.DataChange.PreviousUrlPatterns do
  @path_roots ["show", "edit", "history", "destroy"]

  # user type is special case
  def path_patterns("users") do
    "CONCAT('/site/account/show/', id), CONCAT('/site/account/show/', id, '-*')"
  end

  def path_patterns(type_path_key) do
    statements = Enum.reduce(@path_roots, [], fn root, acc ->
      acc ++
      ["CONCAT('/', B.urlified_name, '/#{type_path_key}/#{root}/', T1.id),
      CONCAT('/', B.urlified_name, '/#{type_path_key}/#{root}/', T1.id, '-*')"]
    end)

    Enum.join(statements, ",")
  end
end
