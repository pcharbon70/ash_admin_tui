defmodule AshAdminTui.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/yourusername/ash_admin_tui"

  def project do
    [
      app: :ash_admin_tui,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AshAdminTui.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    []
  end

  defp description do
    """
    A Terminal User Interface (TUI) for AshAdmin, providing full admin functionality
    for Ash Framework applications through a cross-platform terminal-based interface.
    """
  end

  defp package do
    [
      name: "ash_admin_tui",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "LICENSE.md"]
    ]
  end
end
