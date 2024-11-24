defmodule Forex.ParserTest do
  use ExUnit.Case, async: true

  import Forex.Support.FeedFixtures

  alias Forex.Feed

  test "parsing the body of a single day returns the daily rate" do
    body = daily_feed_fixture()

    list_of_rates =
      Feed.Parser.parse_rates(body)

    assert [%{rates: [%{currency: "USD", rate: "1.0772"} | _], time: "2024-11-08"}] =
             list_of_rates

    assert length(list_of_rates) == 1
  end

  test "parsing the body of multiple rates returns a valid list of map rates" do
    body = multiple_days_feed_fixture()

    list_of_rates = Feed.Parser.parse_rates(body)

    assert [%{rates: [%{currency: "USD", rate: "1.0772"} | _], time: "2024-11-08"} | _] =
             list_of_rates

    assert length(list_of_rates) > 1
  end
end
