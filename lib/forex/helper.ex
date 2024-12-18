defmodule Forex.Helper do
  @moduledoc """
  The `Forex.Helper` module provides helper functions, for example, for
  formatting the exchange rates values.
  """

  @doc """
  Convert the currency code to a default string representation (uppercase string).


  ## Examples

      iex> Forex.Helper.stringify_code(:usd)
      "USD"

      iex> Forex.Helper.stringify_code("usd")
      "USD"

      iex> Forex.Helper.stringify_code("USD")
      "USD"

      iex> Forex.Helper.stringify_code(:USD)
      "USD"

      iex> Forex.Helper.stringify_code(:usd)
      "USD"

      iex> Forex.Helper.stringify_code("usd")
      "USD"

      iex> Forex.Helper.stringify_code("USD")
      "USD"

      iex> Forex.Helper.stringify_code(:USD)
      "USD"

      iex> Forex.Helper.stringify_code(1)
      ** (FunctionClauseError) no function clause matching in Forex.Helper.stringify_code/1

  """
  def stringify_code(code) when is_atom(code), do: Atom.to_string(code) |> String.upcase()
  def stringify_code(code) when is_binary(code), do: String.upcase(code)

  @doc """
  Conver the binary currency code to an atom representation.

  ## Examples

        iex> Forex.Helper.atomize_code("usd")
        :usd

        iex> Forex.Helper.atomize_code(:usd)
        :usd

        iex> Forex.Helper.atomize_code("USD")
        :usd

        iex> Forex.Helper.atomize_code(:USD)
        :usd

        iex> Forex.Helper.atomize_code("uSD")
        :usd

        iex> Forex.Helper.atomize_code(1)
        ** (FunctionClauseError) no function clause matching in Forex.Helper.atomize_code/1

  """
  def atomize_code(code) when is_binary(code) do
    String.downcase(code) |> String.to_existing_atom()
  end

  def atomize_code(code) when is_atom(code) do
    Atom.to_string(code)
    |> String.downcase()
    |> String.to_existing_atom()
  end

  @doc """
  Format the rate value based on the `format` option

  ## Examples

      iex> Forex.Helper.format_value("1.2345", :string)
      "1.2345"

      iex> Forex.Helper.format_value("1.2345", :decimal)
      Decimal.new("1.2345")

      iex> Forex.Helper.format_value("1.2345", :decimal)
      Decimal.new("1.2345")

      iex> Forex.Helper.format_value("1.2345", :string)
      "1.2345"

      iex> Forex.Helper.format_value(1.2345, :decimal)
      Decimal.new("1.2345")

      iex> Forex.Helper.format_value(1.2345, :string)
      "1.2345"

      iex> Forex.Helper.format_value(Decimal.new("1.2345"), :decimal)
      Decimal.new("1.2345")

      iex> Forex.Helper.format_value(Decimal.new("1.2345"), :string)
      "1.2345"

      iex> Forex.Helper.format_value(1.2345, :number)
      ** (Forex.FormatError) Invalid format value: number
  """
  def format_value(value, :string) when is_binary(value), do: value
  def format_value(value, :decimal) when is_binary(value), do: Decimal.new(value)
  def format_value(value, :string) when is_number(value), do: to_string(value)
  def format_value(value, :decimal) when is_number(value), do: to_string(value) |> Decimal.new()
  def format_value(%Decimal{} = value, :string), do: Decimal.to_string(value)
  def format_value(%Decimal{} = value, :decimal), do: value
  def format_value(_, format), do: raise(Forex.FormatError, "Invalid format value: #{format}")

  @doc """
  Round the rate value based on the `round` option

  ## Examples

        iex> Forex.Helper.round_value(1.2345, 2)
        1.23

        iex> Forex.Helper.round_value(1.2345, 4)
        1.2345

        iex> Forex.Helper.round_value(1.2345, 0)
        1.0

        iex> Forex.Helper.round_value(1.2345, 15)
        1.2345

        iex> Forex.Helper.round_value(Decimal.new("1.2345"), 2)
        Decimal.new("1.23")

        iex> Forex.Helper.round_value(Decimal.new("1.2345"), 4)
        Decimal.new("1.2345")

        iex> Forex.Helper.round_value(Decimal.new("1.2345"), 0)
        Decimal.new("1")

        iex> Forex.Helper.round_value("1.2345", 2)
        "1.23"

        iex> Forex.Helper.round_value("1.2345", 4)
        "1.2345"

        iex> Forex.Helper.round_value("1.2345", nil)
        "1.2345"

        iex> Forex.Helper.round_value(nil, 2)
        nil

        iex> Forex.Helper.round_value(1.2345, 16)
        ** (FunctionClauseError) no function clause matching in Forex.Helper.round_value/2
  """

  def round_value(nil, _), do: nil

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

  ## Examples

      iex> Forex.Helper.parse_date("2020-01-01")
      {:ok, ~D[2020-01-01]}

      iex> Forex.Helper.parse_date("2020-01-01T00:00:00Z")
      {:ok, ~D[2020-01-01]}

      iex> Forex.Helper.parse_date({1982, 2, 25})
      {:ok, ~D[1982-02-25]}

      iex> Forex.Helper.parse_date(~D[2020-01-01])
      {:ok, ~D[2020-01-01]}

      iex> Forex.Helper.parse_date(~U[2020-01-01T00:00:00Z])
      {:ok, ~D[2020-01-01]}

      iex> Forex.Helper.parse_date("2020-01-01T00:00:00")
      {:error, :invalid_date}

      iex> Forex.Helper.parse_date("1982-02-31T00:00:00Z")
      {:error, :invalid_date}

      iex> Forex.Helper.parse_date(1982)
      nil
  """
  def parse_date(string) when is_binary(string) do
    with {:ok, date} <- Date.from_iso8601(string) do
      parse_date(date)
    else
      _ ->
        with {:ok, datetime, _} <- DateTime.from_iso8601(string) do
          parse_date(datetime)
        else
          _ -> {:error, :invalid_date}
        end
    end
  end

  def parse_date({year, month, day}) do
    Date.new(year, month, day)
  end

  def parse_date(%DateTime{} = datetime) do
    {:ok, DateTime.to_date(datetime)}
  end

  def parse_date(%Date{} = date), do: {:ok, date}

  def parse_date(_), do: nil

  @doc """
  Map the date to a `Date` struct
  or `nil` if the date cannot be parsed.

  ## Examples

      iex> Forex.Helper.map_date("2020-01-01")
      ~D[2020-01-01]

      iex> Forex.Helper.map_date("2020-01-01T00:00:00Z")
      ~D[2020-01-01]

      iex> Forex.Helper.map_date({1982, 2, 25})
      ~D[1982-02-25]

      iex> Forex.Helper.map_date(~D[2020-01-01])
      ~D[2020-01-01]

      iex> Forex.Helper.map_date(~U[2020-01-01T00:00:00Z])
      ~D[2020-01-01]

      iex> Forex.Helper.map_date("2020-01-01T00:00:00")
      nil

      iex> Forex.Helper.map_date("1982-02-31T00:00:00Z")
      nil

      iex> Forex.Helper.map_date(1982)
      nil
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

  ## Examples

      iex> r = Forex.Helper.cache_memory_usage(:ets)
      iex> r |> String.contains?("MB")
      true
  """
  def cache_memory_usage(:ets) do
    words = :ets.info(:forex_cache, :memory)
    word_size = :erlang.system_info(:wordsize)
    memory = words * word_size / (1024 * 1024)

    "#{Float.round(memory, 2)} MB"
  end
end
