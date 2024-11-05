defmodule Forex.Helper do
  @moduledoc """
  The `Forex.Helper` module provides helper functions, for example, for
  formatting the exchange rates values.
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
  def format_value(_, format), do: raise(Forex.FormatError, "Invalid format value: #{format}")

  @doc """
  Round the rate value based on the `round` option
  """
  def round_value(value, nil), do: value

  def round_value(value, precision)
      when is_number(value) and is_integer(precision) and precision >= 0 and precision <= 15 do
    Float.round(value, precision)
  end

  def round_value(%Decimal{} = value, precision) when is_integer(precision) do
    Decimal.round(value, precision)
  end

  def round_value(value, precision) when is_binary(value) do
    Decimal.new(value)
    |> Decimal.round(precision)
    |> Decimal.to_string()
  end

  @doc """
  Attempt to parse a date from a binary string in ISO 8601 format
  """
  def parse_date(string) when is_binary(string) do
    Date.from_iso8601(string)
  end

  def parse_date({year, month, day}) do
    Date.new(year, month, day)
  end

  def parse_date(%DateTime{} = datetime) do
    DateTime.to_date(datetime)
  end

  def parse_date(%Date{} = date), do: date

  def parse_date(_), do: nil

  @doc """
  Map the date to a `Date` struct
  or `nil` if the date cannot be parsed.
  """
  def map_date(date) do
    case parse_date(date) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  @doc """
  Cache memory usage in megabytes.
  Useful for debugging and monitoring the... cache memory usage.
  """
  def cache_memory_usage(:ets) do
    words = :ets.info(:forex_cache, :memory)
    word_size = :erlang.system_info(:wordsize)
    memory = words * word_size / (1024 * 1024)

    "#{Float.round(memory, 2)} MB"
  end
end
