defmodule ExtractionPoint.SystemSetting do
  use Ecto.Schema

  import Ecto.Query

  schema "system_settings" do
    field :name, :string
    field :value, :string
  end

  def select_value() do
    from(s in __MODULE__, select: s.value)
  end
end
