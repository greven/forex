defmodule Forex.Formatter do
  @moduledoc """
  The `Forex.Formatter` module is responsible for formatting the
  exchange rates values in the desired format.
  """

    @doc """
    Format the rate value based on the `format` option
    """
    def format_value(value, :string) when is_binary(value), do: value
    def format_value(value, :decimal) when is_binary(value), do: Decimal.new(value)
    def format_value(value, :string) when is_number(value), do: to_string(value)
    def format_value(value, :decimal) when is_number(value), do: Decimal.new(value)
    def format_value(%Decimal{} = value, :string), do: Decimal.to_string(value)
    def format_value(%Decimal{} = value, :decimal), do: value
end
