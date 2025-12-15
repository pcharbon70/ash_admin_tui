defmodule Mix.Tasks.AshAdmin.Tui do
  @moduledoc """
  Launches the AshAdmin TUI (Terminal User Interface).

  This task starts the AshAdmin TUI application, providing a terminal-based
  interface for administering Ash Framework applications.

  ## Usage

      $ mix ash_admin.tui

  The TUI will launch and display a welcome screen. Press 'Q' to quit.

  ## Options

  This task accepts no options in the MVP. Future versions may support:
  - `--api-url` - Override API URL
  - `--theme` - Override UI theme
  - `--log-level` - Override logging level

  ## Configuration

  The TUI can be configured via:
  - Configuration files (config/config.exs, config/dev.exs, etc.)
  - Environment variables (ASH_ADMIN_API_URL, ASH_ADMIN_LOG_LEVEL, etc.)

  See `AshAdminTui.Config` for available configuration options.

  ## Keyboard Shortcuts

  - `Q` or `q` - Quit the application

  ## Stopping the Application

  The application can be stopped by:
  - Pressing `Q` or `q` in the TUI
  - Pressing `Ctrl-C` twice (SIGINT)
  """

  use Mix.Task

  @shortdoc "Launch AshAdmin TUI"

  @impl Mix.Task
  def run(_args) do
    # Start the application and its dependencies
    Mix.Task.run("app.start")

    # Display startup message
    Mix.shell().info("Starting AshAdmin TUI...")
    Mix.shell().info("Press 'Q' to quit")
    Mix.shell().info("")

    # Keep the task running indefinitely
    # The application will handle its own shutdown via the :stop command
    # from the Root component when the user presses 'Q'
    #
    # NOTE: This task is not covered by automated tests because:
    # 1. Process.sleep(:infinity) makes the task non-terminating
    # 2. Testing requires spawning in a separate process and killing it
    # 3. The task is simple enough to be verified manually
    # 4. The underlying components (Application, Runtime, Root) are fully tested
    #
    # Manual testing: Run `mix ash_admin.tui` and verify:
    # - Application starts without errors
    # - Welcome screen is displayed
    # - Pressing 'Q' quits gracefully
    Process.sleep(:infinity)
  end
end
