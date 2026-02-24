defmodule Forex.OptionsTest do
  use ExUnit.Case

  alias Forex.Options

  describe "rates_options/1" do
    test "schema returns the unvalidated NimbleOptions struct" do
      assert %NimbleOptions{} = Options.rates_schema()
    end

    test "returns the correct default options" do
      expected =
        [
          use_cache: true,
          keys: :atoms,
          round: 5,
          format: :decimal,
          base: :eur
        ]
        |> Enum.sort()

      actual = Options.rates_options() |> Enum.sort()
      assert expected == actual
    end

    test "merges custom options" do
      opts =
        Options.rates_options(
          base: :usd,
          format: :string,
          round: 2,
          symbols: [:eur, :usd, :gbp],
          use_cache: false
        )

      assert opts[:base] == :usd
      assert opts[:format] == :string
      assert opts[:round] == 2
      assert opts[:symbols] == [:eur, :usd, :gbp]
      assert opts[:use_cache] == false
    end

    test "validates option values" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Options.rates_options(format: :invalid)
      end
    end
  end

  describe "fetcher_supervisor_options/1" do
    test "schema returns the unvalidated NimbleOptions struct" do
      assert %NimbleOptions{} = Options.fetcher_supervisor_schema()
    end

    test "returns the correct default options" do
      expected = [auto_start: true] |> Enum.sort()
      actual = Options.fetcher_supervisor_options() |> Enum.sort()
      assert expected == actual
    end
  end

  describe "fetcher_options/1" do
    test "schema returns the unvalidated NimbleOptions struct" do
      assert %NimbleOptions{} = Options.fetcher_schema()
    end

    test "returns the correct default options" do
      default_timer = :timer.hours(12)

      expected = [use_cache: true, schedular_interval: default_timer] |> Enum.sort()
      actual = Options.fetcher_options() |> Enum.sort()
      assert expected == actual
    end
  end

  describe "currency_options/1" do
    test "schema returns the unvalidated NimbleOptions struct" do
      assert %NimbleOptions{} = Options.currency_schema()
    end

    test "returns the correct default options" do
      expected = [round: 5, format: :decimal] |> Enum.sort()
      actual = Options.currency_options() |> Enum.sort()
      assert expected == actual
    end

    test "merges custom options" do
      opts =
        Options.currency_options(
          format: :string,
          round: 2
        )

      assert opts[:format] == :string
      assert opts[:round] == 2
    end

    test "validates option values" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Options.currency_options(format: :invalid)
      end
    end
  end
end
