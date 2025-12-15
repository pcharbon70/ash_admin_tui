defmodule AshAdminTui.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/yourusername/ash_admin_tui"

  def project do
    # Verify OTP version meets minimum requirement for TUI functionality
    verify_otp_version()

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
      dialyzer: dialyzer()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp verify_otp_version do
    otp_release = String.to_integer(System.otp_release())
    minimum_otp = 28

    if otp_release < minimum_otp do
      Mix.raise("""
      AshAdmin TUI requires Erlang/OTP #{minimum_otp} or later.
      You are currently running OTP #{otp_release}.

      Please upgrade your Erlang/OTP installation to version #{minimum_otp} or later.
      """)
    end
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
    [
      # Core dependencies
      {:term_ui, "~> 0.2.0"},
      {:ash, "~> 3.0"},
      {:ash_admin, "~> 0.11"},
      {:jason, "~> 1.4"},

      # Development dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:mimic, "~> 1.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test}
    ]
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

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit],
      flags: [
        :error_handling,
        :underspecs,
        :unmatched_returns
      ],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end
end
