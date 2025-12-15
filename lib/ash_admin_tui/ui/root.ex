defmodule AshAdminTui.UI.Root do
  @moduledoc """
  Root TermUI component implementing the Elm Architecture pattern.

  This module serves as the entry point for all UI rendering and state management
  in the AshAdmin TUI application. It follows the Elm Architecture with init, update,
  and view functions, providing a functional approach to terminal UI development.

  ## State Structure

  The component maintains:
  - `:view` - Current view mode (`:welcome` for MVP)
  - `:quit_requested` - Boolean indicating user requested exit
  """

  alias TermUI.Event
  alias TermUI.Widget.{Label, Block}

  @doc """
  Initializes the root component state.

  Returns the initial state map.

  ## Examples

      iex> AshAdminTui.UI.Root.init([])
      %{view: :welcome, quit_requested: false}
  """
  def init(_opts) do
    %{
      view: :welcome,
      quit_requested: false
    }
  end

  @doc """
  Converts terminal events to application messages.

  Maps keyboard input events to semantic messages that the update function
  can process. Currently handles the 'q' key for quitting the application.
  """
  def event_to_msg(%Event.Key{key: :char, char: "q"}, _state), do: {:msg, :quit}
  def event_to_msg(%Event.Key{key: :char, char: "Q"}, _state), do: {:msg, :quit}
  def event_to_msg(_event, _state), do: :ignore

  @doc """
  Updates the application state based on messages.

  Processes messages from events and returns updated state and commands.
  The :quit message sets quit_requested and returns :stop command to exit.
  """
  def update(:quit, state) do
    new_state = %{state | quit_requested: true}
    {new_state, [:stop]}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the terminal UI based on current state.

  Creates a simple welcome screen for the MVP.
  Returns TermUI view specification using widgets.
  """
  def view(state) do
    content = welcome_content(state)

    {Block, %{
      title: "AshAdmin TUI",
      title_align: :center,
      border: :single
    }, [
      {Label, %{
        text: content,
        align: :center
      }}
    ]}
  end

  # Private helper to generate welcome content based on state
  defp welcome_content(%{quit_requested: true}) do
    """


    Shutting down AshAdmin TUI...


    """
  end

  defp welcome_content(_state) do
    """


    Welcome to AshAdmin TUI

    A Terminal User Interface for Ash Framework Administration


    System ready. TermUI integration active.


    Press 'Q' to quit
    """
  end
end
