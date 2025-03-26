defmodule Forex.OptionsTest do
  use ExUnit.Case

  alias Forex.Options

  describe "rates_options/1" do
    test "options/1 returns default options" do
      assert Options.rates_options() == %{
               base: :eur,
               format: :decimal,
               round: 5,
               symbols: nil,
               keys: :atoms,
               use_cache: true,
               feed_fn: nil
             }
    end

    test "options/1 merges custom options" do
      opts =
        Options.rates_options(
          base: :usd,
          format: :string,
          round: 2,
          symbols: [:eur, :usd, :gbp],
          use_cache: false
        )

      assert opts.base == :usd
      assert opts.format == :string
      assert opts.round == 2
      assert opts.symbols == [:eur, :usd, :gbp]
      assert opts.use_cache == false
    end

    test "validates option values" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Options.rates_options(format: :invalid)
      end
    end
  end
end
