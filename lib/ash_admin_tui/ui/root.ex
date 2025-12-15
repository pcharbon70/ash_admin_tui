defmodule AshAdminTui.UI.Root do
  @moduledoc """
  Root TermUI component implementing the Elm Architecture pattern.

  This module serves as the entry point for all UI rendering and state management
  in the AshAdmin TUI application. It follows the Elm Architecture with init, update,
  and view functions, providing a functional approach to terminal UI development.

  ## State Structure

  The component maintains:
  - `:quit_requested` - Boolean indicating user requested exit
  - `:layout` - Layout component state (terminal size, focus management)
  """

  alias TermUI.Event
  alias TermUI.Widget.{Block, Label}
  alias AshAdminTui.Components.Layout

  @doc """
  Initializes the root component state.

  Returns the initial state map with layout component initialized.

  ## Examples

      iex> state = AshAdminTui.UI.Root.init([])
      iex> Map.has_key?(state, :layout)
      true
      iex> state.quit_requested
      false
  """
  def init(_opts) do
    %{
      quit_requested: false,
      layout: Layout.init([])
    }
  end

  @doc """
  Converts terminal events to application messages.

  Maps keyboard input events to semantic messages. Handles quit keys and
  delegates other events to the Layout component for processing.
  """
  def event_to_msg(%Event.Key{key: :char, char: "q"}, _state), do: {:msg, :quit}
  def event_to_msg(%Event.Key{key: :char, char: "Q"}, _state), do: {:msg, :quit}

  def event_to_msg(event, state) do
    # Delegate to Layout component for focus management and resize handling
    case Layout.event_to_msg(event, state.layout) do
      {:msg, msg} -> {:msg, {:layout, msg}}
      :ignore -> :ignore
    end
  end

  @doc """
  Updates the application state based on messages.

  Processes messages from events and returns updated state and commands.
  The :quit message sets quit_requested and returns :stop command to exit.
  Layout messages are delegated to the Layout component.
  """
  def update(:quit, state) do
    new_state = %{state | quit_requested: true}
    {new_state, [:stop]}
  end

  def update({:layout, layout_msg}, state) do
    {new_layout, commands} = Layout.update(layout_msg, state.layout)
    {%{state | layout: new_layout}, commands}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the terminal UI based on current state.

  Shows shutdown screen when quitting, otherwise delegates to Layout component
  for rendering the main interface.
  """
  def view(%{quit_requested: true}) do
    {Block, %{
      title: "AshAdmin TUI",
      title_align: :center,
      border: :single
    }, [
      {Label, %{
        text: """


        Shutting down AshAdmin TUI...


        """,
        align: :center
      }}
    ]}
  end

  def view(state) do
    Layout.view(state.layout)
  end
end
