defmodule TupleEncoder do
  @moduledoc """
  Necessary for json encoding of Geo.Point coordinates
  """

  defimpl Jason.Encoder, for: Tuple do
    def encode(data, opts) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Jason.Encode.list(opts)
    end
  end
end
