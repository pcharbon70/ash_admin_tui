defmodule AshAdminTui.Components.Layout do
  @moduledoc """
  Layout Manager Component for AshAdmin TUI.

  The layout manager orchestrates the physical screen layout, dividing the terminal
  into regions for different UI components. It uses TermUI's widgets to create a
  responsive layout that adapts to terminal size while maintaining proper proportions
  and minimum dimensions.

  ## Layout Structure

  ```
  ┌─────────────────────────────────────────┐
  │         Top Bar (2 lines)               │ <- Fixed height
  ├──────────────┬──────────────────────────┤
  │              │                          │
  │   Sidebar    │     Content Area         │ <- Flexible height
  │   (25% min   │     (Remaining)          │
  │    30 chars) │                          │
  │              │                          │
  ├──────────────┴──────────────────────────┤
  │    Status Bar (1 line)                  │ <- Fixed height
  └─────────────────────────────────────────┘
  ```

  ## State

  - `:terminal_size` - Current terminal dimensions `{width, height}`
  - `:focus` - Which component has keyboard focus (`:sidebar` | `:content`)

  ## Focus Management

  The layout tracks which component has keyboard focus and provides visual feedback
  through highlighted borders. The Tab key toggles focus between sidebar and content.
  """

  alias TermUI.Event
  alias TermUI.Widget.{Block, Label, SplitPane, VStack}
  alias AshAdminTui.Components.TopBar

  @doc """
  Initializes the layout component state.

  Returns initial state with default terminal size, sidebar focus, and mock session data.

  ## Examples

      iex> state = AshAdminTui.Components.Layout.init([])
      iex> state.terminal_size
      {80, 24}
      iex> state.focus
      :sidebar
      iex> state.navigation
      %{domain: "Home", resource: nil, record_id: nil}
  """
  @spec init(keyword()) :: map()
  def init(_opts) do
    %{
      terminal_size: {80, 24},
      focus: :sidebar,
      # Session state (mock data for Phase 2)
      navigation: %{domain: "Home", resource: nil, record_id: nil},
      actor: nil,
      tenant: nil
    }
  end

  @doc """
  Converts terminal events to application messages.

  Maps keyboard events to focus management and resize events to terminal size updates.
  """
  @spec event_to_msg(Event.t(), map()) :: {:msg, any()} | :ignore
  def event_to_msg(%Event.Key{key: :char, char: "\t"}, _state) do
    # Tab key toggles focus between sidebar and content
    {:msg, :toggle_focus}
  end

  def event_to_msg(%Event.Resize{width: width, height: height}, _state) do
    # Terminal resize updates terminal_size in state
    {:msg, {:resize, {width, height}}}
  end

  def event_to_msg(_event, _state) do
    # All other events are passed to the focused component
    :ignore
  end

  @doc """
  Updates layout state based on messages.

  Handles focus toggling and terminal resize messages.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update(:toggle_focus, state) do
    new_focus =
      case state.focus do
        :sidebar -> :content
        :content -> :sidebar
      end

    {%{state | focus: new_focus}, []}
  end

  def update({:resize, {width, height}}, state) do
    {%{state | terminal_size: {width, height}}, []}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the layout with all four sections.

  Creates a vertical stack containing:
  1. Top bar (fixed 2 lines)
  2. Split pane with sidebar and content (flexible)
  3. Status bar (fixed 1 line)

  The sidebar takes 25% width with a minimum of 30 characters.
  Focused component has a highlighted border.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    {width, height} = state.terminal_size

    # Calculate sidebar width (25% of total, minimum 30 characters)
    sidebar_width = max(div(width, 4), 30)

    # Calculate heights for fixed sections
    top_bar_height = 2
    status_bar_height = 1
    content_height = height - top_bar_height - status_bar_height

    {VStack, %{}, [
      # Top Bar (placeholder for now)
      render_top_bar(state, width, top_bar_height),

      # Main content area with split pane
      {SplitPane, %{
        direction: :horizontal,
        split_position: sidebar_width,
        height: content_height
      }, [
        # Sidebar
        render_sidebar(state),

        # Content Area
        render_content(state)
      ]},

      # Status Bar (placeholder for now)
      render_status_bar(state, width, status_bar_height)
    ]}
  end

  # Private helper functions

  defp render_top_bar(state, width, height) do
    # Prepare session state for TopBar component
    top_bar_state = %{
      navigation: state.navigation,
      actor: state.actor,
      tenant: state.tenant,
      width: width - 4  # Account for border padding
    }

    {Block, %{
      border: :single,
      height: height
    }, [
      TopBar.view(top_bar_state)
    ]}
  end

  defp render_sidebar(state) do
    border_style = if state.focus == :sidebar, do: :double, else: :single

    {Block, %{
      title: "Resources",
      border: border_style,
      border_color: if(state.focus == :sidebar, do: :cyan, else: :white)
    }, [
      {Label, %{
        text: """


        [Sidebar Content]

        Navigation tree will go here

        """,
        align: :center
      }}
    ]}
  end

  defp render_content(state) do
    border_style = if state.focus == :content, do: :double, else: :single

    {Block, %{
      title: "Content",
      border: border_style,
      border_color: if(state.focus == :content, do: :cyan, else: :white)
    }, [
      {Label, %{
        text: """


        [Content Area]

        List/Detail/Form views will go here

        """,
        align: :center
      }}
    ]}
  end

  defp render_status_bar(_state, _width, height) do
    {Block, %{
      border: :single,
      height: height
    }, [
      {Label, %{
        text: "[Tab] Switch Focus  [Q] Quit"
      }}
    ]}
  end
end
