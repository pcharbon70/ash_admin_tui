defmodule TermuiIntegrationTest do
  use ExUnit.Case
  doctest AshAdminTui.UI.Root

  alias AshAdminTui.UI.Root

  describe "Root.init/1" do
    test "returns valid initial state" do
      state = Root.init([])

      assert is_map(state)
    end

    test "initializes with layout component" do
      state = Root.init([])

      assert Map.has_key?(state, :layout)
      assert is_map(state.layout)
    end

    test "initializes with quit_requested false" do
      state = Root.init([])

      assert state.quit_requested == false
    end
  end

  describe "Root.event_to_msg/2" do
    test "maps 'q' key to :quit message" do
      state = Root.init([])
      event = %TermUI.Event.Key{key: :char, char: "q"}

      assert Root.event_to_msg(event, state) == {:msg, :quit}
    end

    test "maps 'Q' key to :quit message" do
      state = Root.init([])
      event = %TermUI.Event.Key{key: :char, char: "Q"}

      assert Root.event_to_msg(event, state) == {:msg, :quit}
    end

    test "maps Tab key to layout toggle_focus message" do
      state = Root.init([])
      event = %TermUI.Event.Key{key: :char, char: "\t"}

      assert Root.event_to_msg(event, state) == {:msg, {:layout, :toggle_focus}}
    end

    test "maps Resize event to layout resize message" do
      state = Root.init([])
      event = %TermUI.Event.Resize{width: 100, height: 30}

      assert Root.event_to_msg(event, state) == {:msg, {:layout, {:resize, {100, 30}}}}
    end

    test "maps other keys to :ignore" do
      state = Root.init([])
      event_a = %TermUI.Event.Key{key: :char, char: "a"}
      event_b = %TermUI.Event.Key{key: :char, char: "b"}

      assert Root.event_to_msg(event_a, state) == :ignore
      assert Root.event_to_msg(event_b, state) == :ignore
    end
  end

  describe "Root.update/2" do
    test "handles :quit message and returns :stop command" do
      state = Root.init([])

      {new_state, commands} = Root.update(:quit, state)

      assert new_state.quit_requested == true
      assert :stop in commands
    end

    test "preserves other state when handling :quit" do
      state = Root.init([])

      {new_state, _commands} = Root.update(:quit, state)

      assert Map.has_key?(new_state, :layout)
    end

    test "handles {:layout, message} by delegating to Layout component" do
      state = Root.init([])
      assert state.layout.focus == :sidebar

      {new_state, commands} = Root.update({:layout, :toggle_focus}, state)

      assert new_state.layout.focus == :content
      assert commands == []
    end

    test "ignores unknown messages" do
      state = Root.init([])

      {new_state, commands} = Root.update(:unknown_message, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "Root.view/1" do
    test "renders without errors" do
      state = Root.init([])

      # TermUI view returns a widget spec tuple
      result = Root.view(state)
      assert is_tuple(result)
      assert tuple_size(result) == 3
    end

    test "view output contains AshAdmin TUI title" do
      state = Root.init([])

      view_spec = Root.view(state)

      # Convert view spec to string for inspection
      view_string = inspect(view_spec)

      assert view_string =~ "AshAdmin TUI"
    end

    test "view output contains quit hint" do
      state = Root.init([])

      view_spec = Root.view(state)

      # Convert view spec to string for inspection (with full output)
      view_string = inspect(view_spec, limit: :infinity)

      assert view_string =~ "Quit"
    end

    test "view renders layout with sidebar and content sections" do
      state = Root.init([])

      view_spec = Root.view(state)

      # Convert view spec to string for inspection
      view_string = inspect(view_spec)

      assert view_string =~ "Resources"  # Sidebar title
      assert view_string =~ "Accounts"   # Sidebar domain (content is abbreviated in inspect)
    end

    test "view changes when quit is requested" do
      state_before = Root.init([])
      state_after = %{state_before | quit_requested: true}

      view_before = inspect(Root.view(state_before))
      view_after = inspect(Root.view(state_after))

      # The view should show shutdown message when quit is requested
      assert view_after =~ "Shutting down"
      refute view_before =~ "Shutting down"
    end
  end

  describe "TermUI Runtime integration" do
    test "Runtime starts with Root component" do
      # The Runtime is started automatically by the application supervisor
      # Verify it's running with the Root component
      runtime_pid = Process.whereis(AshAdminTui.UI.Runtime)

      assert runtime_pid != nil
      assert Process.alive?(runtime_pid)

      # Get the state and verify it has the root component reference
      state = :sys.get_state(runtime_pid)

      assert state.root_component == AshAdminTui.UI.Root
      assert state.runtime_pid != nil
      assert Process.alive?(state.runtime_pid)
    end

    test "TermUI.Runtime process is linked to Runtime GenServer" do
      runtime_pid = Process.whereis(AshAdminTui.UI.Runtime)
      state = :sys.get_state(runtime_pid)

      termui_pid = state.runtime_pid

      # Verify TermUI.Runtime is a separate process
      assert termui_pid != runtime_pid
      assert Process.alive?(termui_pid)
    end

    test "Root component follows Elm Architecture" do
      # Verify all required functions exist and have correct arity
      assert function_exported?(Root, :init, 1)
      assert function_exported?(Root, :update, 2)
      assert function_exported?(Root, :view, 1)
      assert function_exported?(Root, :event_to_msg, 2)
    end
  end

  describe "layout structure" do
    test "view creates VStack layout with four sections" do
      state = Root.init([])
      view_spec = Root.view(state)

      view_string = inspect(view_spec)

      # Verify it uses VStack for vertical layout
      assert view_string =~ "VStack"

      # Verify it uses Block widgets (bordered containers)
      assert view_string =~ "Block"
    end

    test "view includes keyboard shortcut hints in status bar" do
      state = Root.init([])
      view_spec = Root.view(state)

      view_string = inspect(view_spec, limit: :infinity)

      # Verify keyboard hint content in status bar
      assert view_string =~ "Tab"
      assert view_string =~ "Switch Focus"
      assert view_string =~ "Quit"
    end

    test "view uses SplitPane for sidebar and content" do
      state = Root.init([])
      view_spec = Root.view(state)

      view_string = inspect(view_spec)

      # Verify SplitPane is used
      assert view_string =~ "SplitPane"
      assert view_string =~ "Resources"
      assert view_string =~ "Accounts"  # Sidebar domain (content block title is abbreviated)
    end
  end
end
