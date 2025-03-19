defmodule Forex.FeedError do
  @moduledoc """
  Exception for feed errors.
  """

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Forex.CurrencyError do
  @moduledoc """
  Exception for currency errors.
  """

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Forex.FormatError do
  @moduledoc """
  Exception for format errors.
  """

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Forex.DateError do
  @moduledoc """
  Exception for date errors.
  """

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
