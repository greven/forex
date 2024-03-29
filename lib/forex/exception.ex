defmodule Forex.FeedError do
  @moduledoc false

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Forex.CurrencyError do
  @moduledoc false

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Forex.FormatError do
  @moduledoc false

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
