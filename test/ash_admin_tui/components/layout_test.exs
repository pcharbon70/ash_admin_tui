defmodule AshAdminTui.Components.LayoutTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Components.Layout

  alias AshAdminTui.Components.Layout
  alias TermUI.Event
  alias TermUI.Widget.{VStack, SplitPane, Block}

  # Helper function to create minimal valid state for testing
  defp minimal_state(overrides \\ %{}) do
    Map.merge(
      %{
        terminal_size: {80, 24},
        focus: :sidebar,
        navigation: %{domain: "Home", resource: nil, record_id: nil},
        actor: nil,
        tenant: nil,
        view: nil,
        sidebar: %{domains: [], selected_index: 0, expanded_domains: MapSet.new()},
        content_area: %{
          view_type: nil,
          view_states: %{list: %{}, detail: %{}, form: %{}, action: %{}},
          error_message: nil,
          loading_message: nil,
          previous_view: nil
        },
        status_bar: %{toast: nil}
      },
      overrides
    )
  end

  describe "init/1" do
    test "initializes with correct default state" do
      state = Layout.init([])

      assert state.terminal_size == {80, 24}
      assert state.focus == :sidebar
      assert state.navigation == %{domain: "Home", resource: nil, record_id: nil}
      assert state.actor == nil
      assert state.tenant == nil
      assert state.view == nil
      assert is_map(state.sidebar)
      assert is_list(state.sidebar.domains)
      assert is_map(state.content_area)
      assert state.content_area.view_type == nil
      assert state.status_bar == %{toast: nil}
    end
  end

  describe "event_to_msg/2" do
    test "Tab key generates :toggle_focus message" do
      state = minimal_state()
      event = %Event.Key{key: :char, char: "\t"}

      assert Layout.event_to_msg(event, state) == {:msg, :toggle_focus}
    end

    test "Resize event generates {:resize, {width, height}} message" do
      state = minimal_state()
      event = %Event.Resize{width: 100, height: 30}

      assert Layout.event_to_msg(event, state) == {:msg, {:resize, {100, 30}}}
    end

    test "other events are ignored" do
      state = minimal_state()
      event = %Event.Key{key: :char, char: "a"}

      assert Layout.event_to_msg(event, state) == :ignore
    end
  end

  describe "update/2" do
    test ":toggle_focus switches from sidebar to content" do
      state = minimal_state()

      {new_state, commands} = Layout.update(:toggle_focus, state)

      assert new_state.focus == :content
      assert commands == []
    end

    test ":toggle_focus switches from content to sidebar" do
      state = minimal_state(%{focus: :content})

      {new_state, commands} = Layout.update(:toggle_focus, state)

      assert new_state.focus == :sidebar
      assert commands == []
    end

    test "{:resize, {width, height}} updates terminal_size" do
      state = minimal_state()

      {new_state, commands} = Layout.update({:resize, {100, 30}}, state)

      assert new_state.terminal_size == {100, 30}
      assert new_state.focus == :sidebar
      assert commands == []
    end

    test "unknown messages return unchanged state" do
      state = minimal_state()

      {new_state, commands} = Layout.update(:unknown, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "view/1" do
    test "renders layout with four sections in VStack" do
      state = minimal_state()

      {widget, _props, children} = Layout.view(state)

      assert widget == VStack
      assert length(children) == 3  # top bar, split pane, status bar
    end

    test "layout has fixed-height top bar (2 lines)" do
      state = minimal_state()

      {VStack, _props, [top_bar | _rest]} = Layout.view(state)
      {Block, top_bar_props, _children} = top_bar

      assert top_bar_props.height == 2
    end

    test "layout has fixed-height status bar (1 line)" do
      state = minimal_state()

      {VStack, _props, children} = Layout.view(state)
      status_bar = List.last(children)
      {Block, status_bar_props, _children} = status_bar

      assert status_bar_props.height == 1
    end

    test "layout contains split pane with sidebar and content" do
      state = minimal_state()

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, split_props, pane_children} = split_pane

      assert split_props.direction == :horizontal
      assert length(pane_children) == 2  # sidebar and content
    end

    test "sidebar takes 25% width of terminal when above minimum" do
      # Use a large terminal where 25% exceeds 30 chars
      state = minimal_state(%{terminal_size: {200, 24}})

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, split_props, _children} = split_pane

      # 25% of 200 = 50 (exceeds minimum of 30)
      assert split_props.split_position == 50
    end

    test "sidebar respects minimum width of 30 characters" do
      # Small terminal where 25% would be less than 30
      state = minimal_state()

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, split_props, _children} = split_pane

      # 25% of 80 = 20, but minimum is 30
      assert split_props.split_position == 30
    end

    test "focused component (sidebar) has double border" do
      state = minimal_state()

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, _split_props, [sidebar | _content]} = split_pane
      {Block, sidebar_props, _children} = sidebar

      assert sidebar_props.border == :double
      assert sidebar_props.border_color == :cyan
    end

    test "unfocused component (content) has single border" do
      state = minimal_state()

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, _split_props, [_sidebar, content]} = split_pane
      {Block, content_props, _children} = content

      assert content_props.border == :single
      assert content_props.border_color == :white
    end

    test "focused component (content) has double border" do
      state = minimal_state(%{focus: :content})

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, _split_props, [_sidebar, content]} = split_pane
      {Block, content_props, _children} = content

      assert content_props.border == :double
      assert content_props.border_color == :cyan
    end

    test "unfocused component (sidebar) has single border" do
      state = minimal_state(%{focus: :content})

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, _split_props, [sidebar | _content]} = split_pane
      {Block, sidebar_props, _children} = sidebar

      assert sidebar_props.border == :single
      assert sidebar_props.border_color == :white
    end

    test "content height accounts for fixed top and status bars" do
      state = minimal_state()

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, split_props, _children} = split_pane

      # Total height 24, minus 2 for top bar, minus 1 for status bar = 21
      assert split_props.height == 21
    end
  end

  describe "focus management integration" do
    test "Tab key properly cycles focus through components" do
      # Start with sidebar focus
      state = Layout.init([])
      assert state.focus == :sidebar

      # First tab -> content focus
      {state1, _} = Layout.update(:toggle_focus, state)
      assert state1.focus == :content

      # Second tab -> back to sidebar focus
      {state2, _} = Layout.update(:toggle_focus, state1)
      assert state2.focus == :sidebar
    end
  end

  describe "resize handling integration" do
    test "resize events update terminal_size in state" do
      state = Layout.init([])
      assert state.terminal_size == {80, 24}

      # Simulate resize event
      event = %Event.Resize{width: 120, height: 40}
      {:msg, msg} = Layout.event_to_msg(event, state)

      {new_state, _} = Layout.update(msg, state)

      assert new_state.terminal_size == {120, 40}
    end

    test "view adapts to new terminal size after resize" do
      state = minimal_state(%{terminal_size: {120, 40}})

      {VStack, _props, [_top_bar, split_pane | _rest]} = Layout.view(state)
      {SplitPane, split_props, _children} = split_pane

      # 25% of 120 = 30 (equals minimum, so that's what we use)
      assert split_props.split_position == 30
      # Height should be 40 - 2 (top) - 1 (status) = 37
      assert split_props.height == 37
    end
  end
end
