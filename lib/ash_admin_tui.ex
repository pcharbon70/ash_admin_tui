defmodule AshAdminTui do
  @moduledoc """
  AshAdminTui provides a Terminal User Interface (TUI) for AshAdmin.

  This module serves as the main entry point for the ash_admin_tui application,
  providing full admin functionality for Ash Framework applications through a
  cross-platform terminal-based interface.

  ## Features

  - Full CRUD operations for Ash resources
  - Resource introspection and navigation
  - Authentication via AshAuthentication
  - Actor impersonation for policy testing
  - Multi-tenancy support
  - Cross-platform terminal UI (Linux, macOS, Windows 10+)
  """

  @doc """
  Returns the application version.
  """
  def version do
    Application.spec(:ash_admin_tui, :vsn) |> to_string()
  end
end
