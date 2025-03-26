defmodule Forex.Support do
  @moduledoc """
  The `Forex.Support` module provides helper functions, for example, for
  formatting the exchange rates values.
  """

  @type parsable_date() ::
          String.t() | Date.t() | DateTime.t() | {integer(), integer(), integer()}

  @doc """
  Convert the currency code to a default string representation (uppercase string).


  ## Examples

      iex> Forex.Support.stringify_code(:usd)
      "USD"

      iex> Forex.Support.stringify_code("usd")
      "USD"

      iex> Forex.Support.stringify_code("USD")
      "USD"

      iex> Forex.Support.stringify_code(:USD)
      "USD"

      iex> Forex.Support.stringify_code(:usd)
      "USD"

      iex> Forex.Support.stringify_code("usd")
      "USD"

      iex> Forex.Support.stringify_code("USD")
      "USD"

      iex> Forex.Support.stringify_code(:USD)
      "USD"

      iex> Forex.Support.stringify_code(1)
      ** (FunctionClauseError) no function clause matching in Forex.Support.stringify_code/1

  """
  @spec stringify_code(atom() | String.t()) :: String.t()
  def stringify_code(code) when is_atom(code), do: Atom.to_string(code) |> String.upcase()
  def stringify_code(code) when is_binary(code), do: String.upcase(code)

  @doc """
  Conver the binary currency code to an existing atom representation.

  ## Examples

        iex> Forex.Support.atomize_code("usd")
        :usd

        iex> Forex.Support.atomize_code(:usd)
        :usd

        iex> Forex.Support.atomize_code("USD")
        :usd

        iex> Forex.Support.atomize_code(:USD)
        :usd

        iex> Forex.Support.atomize_code("uSD")
        :usd

        iex> Forex.Support.atomize_code(1)
        ** (FunctionClauseError) no function clause matching in Forex.Support.atomize_code/1

  """
  @spec atomize_code(atom() | String.t()) :: atom()
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

      iex> Forex.Support.format_value("1.2345", :string)
      "1.2345"

      iex> Forex.Support.format_value("1.2345", :decimal)
      Decimal.new("1.2345")

      iex> Forex.Support.format_value("1.2345", :decimal)
      Decimal.new("1.2345")

      iex> Forex.Support.format_value("1.2345", :string)
      "1.2345"

      iex> Forex.Support.format_value(1.2345, :decimal)
      Decimal.new("1.2345")

      iex> Forex.Support.format_value(1.2345, :string)
      "1.2345"

      iex> Forex.Support.format_value(Decimal.new("1.2345"), :decimal)
      Decimal.new("1.2345")

      iex> Forex.Support.format_value(Decimal.new("1.2345"), :string)
      "1.2345"

      iex> Forex.Support.format_value(1.2345, :number)
      ** (Forex.FormatError) Invalid format value: number
  """
  @spec format_value(number() | binary() | Decimal.t(), :string | :decimal) ::
          formatted_value :: binary() | Decimal.t()
  def format_value(%Decimal{} = value, :decimal), do: value
  def format_value(%Decimal{} = value, :string), do: Decimal.to_string(value)
  def format_value(value, :string) when is_binary(value), do: value
  def format_value(value, :string) when is_number(value), do: to_string(value)
  def format_value(value, :decimal) when is_binary(value), do: Decimal.new(value)
  def format_value(value, :decimal) when is_number(value), do: Decimal.new(to_string(value))
  def format_value(_, format), do: raise(Forex.FormatError, "Invalid format value: #{format}")

  @doc """
  Round the rate value based on the `round` option

  ## Examples

        iex> Forex.Support.round_value(1.2345, 2)
        1.23

        iex> Forex.Support.round_value(1.2345, 4)
        1.2345

        iex> Forex.Support.round_value(1.2345, 0)
        1.0

        iex> Forex.Support.round_value(1.2345, 15)
        1.2345

        iex> Forex.Support.round_value(Decimal.new("1.2345"), 2)
        Decimal.new("1.23")

        iex> Forex.Support.round_value(Decimal.new("1.2345"), 4)
        Decimal.new("1.2345")

        iex> Forex.Support.round_value(Decimal.new("1.2345"), 0)
        Decimal.new("1")

        iex> Forex.Support.round_value("1.2345", 2)
        "1.23"

        iex> Forex.Support.round_value("1.2345", 4)
        "1.2345"

        iex> Forex.Support.round_value("1.2345", nil)
        "1.2345"

        iex> Forex.Support.round_value(nil, 2)
        nil

        iex> Forex.Support.round_value(1.2345, 16)
        ** (FunctionClauseError) no function clause matching in Forex.Support.round_value/2
  """

  @spec round_value(any(), integer() | nil) :: any()
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

      iex> Forex.Support.parse_date("2020-01-01")
      {:ok, ~D[2020-01-01]}

      iex> Forex.Support.parse_date("2020-01-01T00:00:00Z")
      {:ok, ~D[2020-01-01]}

      iex> Forex.Support.parse_date({1982, 2, 25})
      {:ok, ~D[1982-02-25]}

      iex> Forex.Support.parse_date(~D[2020-01-01])
      {:ok, ~D[2020-01-01]}

      iex> Forex.Support.parse_date(~U[2020-01-01T00:00:00Z])
      {:ok, ~D[2020-01-01]}

      iex> Forex.Support.parse_date("2020-01-01T00:00:00")
      {:error, :invalid_date}

      iex> Forex.Support.parse_date("1982-02-31T00:00:00Z")
      {:error, :invalid_date}

      iex> Forex.Support.parse_date(1982)
      {:error, :invalid_date}
  """
  @spec parse_date(parsable_date()) :: {:ok, Date.t()} | {:error, :invalid_date}
  def parse_date(string) when is_binary(string) do
    case Date.from_iso8601(string) do
      {:ok, date} ->
        parse_date(date)

      _ ->
        case DateTime.from_iso8601(string) do
          {:ok, datetime, _} -> parse_date(datetime)
          _ -> {:error, :invalid_date}
        end
    end
  end

  def parse_date(%DateTime{} = datetime) do
    {:ok, DateTime.to_date(datetime)}
  end

  def parse_date(%Date{} = date), do: {:ok, date}
  def parse_date({year, month, day}), do: Date.new(year, month, day)
  def parse_date(_), do: {:error, :invalid_date}

  @doc """
  Map the date to a `Date` struct
  or `nil` if the date cannot be parsed.

  ## Examples

      iex> Forex.Support.map_date("2020-01-01")
      ~D[2020-01-01]

      iex> Forex.Support.map_date("2020-01-01T00:00:00Z")
      ~D[2020-01-01]

      iex> Forex.Support.map_date({1982, 2, 25})
      ~D[1982-02-25]

      iex> Forex.Support.map_date(~D[2020-01-01])
      ~D[2020-01-01]

      iex> Forex.Support.map_date(~U[2020-01-01T00:00:00Z])
      ~D[2020-01-01]

      iex> Forex.Support.map_date("2020-01-01T00:00:00")
      nil

      iex> Forex.Support.map_date("1982-02-31T00:00:00Z")
      nil

      iex> Forex.Support.map_date(1982)
      nil
  """
  @spec map_date(parsable_date()) :: Date.t() | nil
  def map_date(date) do
    case parse_date(date) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
