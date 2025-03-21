defmodule Forex.CacheTest do
  use ExUnit.Case

  import Forex.Support.TestHelpers

  # Define cache implementation tests for shared behaviour
  defmodule CacheTests do
    @callback cache_mod() :: module()

    defmacro __using__(_) do
      quote do
        @behaviour CacheTests

        setup do
          cache = cache_mod()
          cache.init()

          on_exit(:reset_cache, fn ->
            cache.reset()
          end)

          {:ok, cache: cache}
        end

        test "stores and retrieves values", %{cache: cache} do
          now = DateTime.utc_now()
          assert "test_value" = cache.put(:test_key, "test_value", now)
          assert "test_value" = cache.get(:test_key)
        end

        test "handles nil values", %{cache: cache} do
          now = DateTime.utc_now()
          assert nil == cache.put(:nil_key, nil, now)
          assert nil == cache.get(:nil_key)
        end

        test "returns nil for missing keys", %{cache: cache} do
          assert nil == cache.get(:missing_key)
        end

        test "deletes entries", %{cache: cache} do
          now = DateTime.utc_now()
          cache.put(:delete_key, "delete_me", now)
          assert "delete_me" = cache.get(:delete_key)

          cache.delete(:delete_key)
          assert nil == cache.get(:delete_key)
        end

        test "tracks last updated timestamp for all keys", %{cache: cache} do
          now = DateTime.utc_now()
          cache.put(:timestamp_key, "value", now)

          assert {_, timestamp} =
                   cache.last_updated()
                   |> Enum.find(fn {key, _} -> key == :timestamp_key end)

          assert DateTime.compare(timestamp, now) == :eq
        end

        test "tracks last updated timestamp for specific key", %{cache: cache} do
          now = DateTime.utc_now()
          cache.put(:timestamp_key, "value", now)

          assert DateTime.compare(now, cache.last_updated(:timestamp_key)) == :eq
          refute cache.last_updated(:missing_key)
        end

        test "respects TTL returning nil for expired entry", %{cache: cache} do
          past = DateTime.add(DateTime.utc_now(), -2, :second)
          cache.put(:ttl_key, "expired", past)

          assert nil == cache.get(:ttl_key, ttl: 1000)
        end

        test "resolves missing values", %{cache: cache} do
          resolver = fn -> {:ok, "resolved"} end
          assert {:ok, "resolved"} = cache.resolve(:missing, resolver)

          # Second call should use cached value
          assert {:ok, "resolved"} = cache.resolve(:missing, fn -> {:ok, "new"} end)

          # Invalid resolver should return error
          assert {:error, :cache_resolver_failed} = cache.resolve(:missing_too, fn -> "value" end)
        end

        test "resets cache", %{cache: cache} do
          now = DateTime.utc_now()

          # Populate cache
          cache.put(:key1, "value1", now)
          cache.put(:key2, "value2", now)

          # Check cache is populated
          assert "value1" == cache.get(:key1)
          assert "value2" == cache.get(:key2)

          # Reset cache
          cache.reset()

          # Check cache is empty
          assert nil == cache.get(:key1)
          assert nil == cache.get(:key2)

          # # Populate cache again
          cache.put(:key1, "value1", now)
          cache.put(:key2, "value2", now)

          # # Check cache is populated
          assert "value1" == cache.get(:key1)
          assert "value2" == cache.get(:key2)
        end

        test "initialized? returns true if cache table is initialized", %{cache: cache} do
          assert true == cache.initialized?()
        end
      end
    end
  end

  # Test ETS Implementation
  defmodule ETSCacheTest do
    use ExUnit.Case
    use CacheTests

    @impl true
    def cache_mod, do: Forex.Cache.ETS

    setup do
      Application.put_env(:forex, :cache_module, Forex.Cache.ETS)
    end

    test "cache interface" do
      assert Forex.Cache.cache_mod() == Forex.Cache.ETS
    end

    test "terminates cache process", %{cache: cache} do
      assert true == cache.terminate()
    end
  end

  # Test DETS Implementation
  defmodule DETSCacheTest do
    use ExUnit.Case
    use CacheTests

    @impl true
    def cache_mod, do: Forex.Cache.DETS

    test "cache interface" do
      assert Forex.Cache.cache_mod() == Forex.Cache.DETS
    end

    setup do
      Application.put_env(:forex, :cache_module, Forex.Cache.DETS)
    end

    test "persists data between process restarts" do
      cache = cache_mod()
      cache.init()

      now = DateTime.utc_now()
      cache.put(:persist_key, "persist_value", now)

      # Simulate process restart
      cache.terminate()
      cache.init()

      assert "persist_value" == cache.get(:persist_key)
    end

    test "terminates cache process", %{cache: cache} do
      assert :ok == cache.terminate()
    end
  end

  # Test Cache Module Interface
  describe "Forex.Cache interface" do
    test "delegates to configured cache implementation" do
      setup_test_cache()

      cache = Forex.Cache.cache_mod()
      now = DateTime.utc_now()

      assert cache in [Forex.Cache.ETS, Forex.Cache.DETS, Forex.Support.CacheMock]

      Forex.Cache.reset()
      Forex.Cache.init()

      assert is_nil(Forex.Cache.latest_rates())
      assert is_nil(Forex.Cache.last_ninety_days_rates())
      assert is_nil(Forex.Cache.historic_rates())

      ## Last Updated
      assert [] == Forex.Cache.last_updated()

      cache.put(:key1, "value1", now)

      assert now == Forex.Cache.last_updated(:key1)

      ## Resolve
      assert {:ok, :resolved} == Forex.Cache.resolve(:key2, fn -> {:ok, :resolved} end)
      assert {:ok, :resolved} == cache.resolve(:key2, fn -> {:ok, :resolved} end)

      cache.put(:key3, "value3", now)

      assert {:ok, "value3"} == cache.resolve(:key3, fn -> {:ok, :resolved} end)

      ## Delete
      cache.put(:delete_key, "delete_me", now)
      assert "delete_me" == cache.get(:delete_key)
      assert Forex.Cache.delete(:delete_key)

      ## Terminate & Reset
      assert Forex.Cache.terminate()
      assert Forex.Cache.reset()

      ## Init
      assert Forex.Cache.init()
    end
  end
end
