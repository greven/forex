defmodule Mix.Tasks.Forex do
  use Mix.Task

  alias Mix.Tasks

  @shortdoc "Prints Forex help information"

  @moduledoc """
  Prints Forex tasks and their information.

      mix forex
  """

  @version Mix.Project.config()[:version]

  @impl true
  @doc false
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Forex v#{@version}")
  end

  def run(args) do
    {_opts, args} = OptionParser.parse!(args, strict: [])

    case args do
      [] -> general()
      _ -> Mix.raise("Invalid arguments, expected: mix forex")
    end
  end

  defp general do
    Mix.Task.run("app.start")
    Mix.shell().info("Forex v#{Application.spec(:forex, :vsn)}")
    Mix.shell().info("European Central Bank (ECB) exchange rates for Elixir.")
    Mix.shell().info("\n## Options:\n")
    Tasks.Help.run(["--search", "forex."])
  end
end
