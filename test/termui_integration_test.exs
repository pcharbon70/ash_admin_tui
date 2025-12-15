defmodule TermuiIntegrationTest do
  use ExUnit.Case
  doctest AshAdminTui.UI.Root

  alias AshAdminTui.UI.Root

  describe "Root.init/1" do
    test "returns valid initial state" do
      state = Root.init([])

      assert is_map(state)
    end

    test "initializes with welcome view" do
      state = Root.init([])

      assert state.view == :welcome
    end

    test "initializes with quit_requested false" do
      state = Root.init([])

      assert state.quit_requested == false
    end
  end

  describe "Root.event_to_msg/2" do
    test "maps 'q' key to :quit message" do
      state = %{view: :welcome, quit_requested: false}
      event = %TermUI.Event.Key{key: :char, char: "q"}

      assert Root.event_to_msg(event, state) == {:msg, :quit}
    end

    test "maps 'Q' key to :quit message" do
      state = %{view: :welcome, quit_requested: false}
      event = %TermUI.Event.Key{key: :char, char: "Q"}

      assert Root.event_to_msg(event, state) == {:msg, :quit}
    end

    test "maps other keys to :ignore" do
      state = %{view: :welcome, quit_requested: false}
      event_a = %TermUI.Event.Key{key: :char, char: "a"}
      event_b = %TermUI.Event.Key{key: :char, char: "b"}

      assert Root.event_to_msg(event_a, state) == :ignore
      assert Root.event_to_msg(event_b, state) == :ignore
    end

    test "maps unknown events to :ignore" do
      state = %{view: :welcome, quit_requested: false}

      assert Root.event_to_msg(%TermUI.Event.Resize{width: 80, height: 24}, state) == :ignore
      assert Root.event_to_msg(:unknown, state) == :ignore
    end
  end

  describe "Root.update/2" do
    test "handles :quit message and returns :stop command" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, commands} = Root.update(:quit, state)

      assert new_state.quit_requested == true
      assert :stop in commands
    end

    test "preserves other state when handling :quit" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, _commands} = Root.update(:quit, state)

      assert new_state.view == :welcome
    end

    test "handles :noop message without changing state" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, commands} = Root.update(:noop, state)

      assert new_state == state
      assert commands == []
    end

    test "ignores unknown messages" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, commands} = Root.update(:unknown_message, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "Root.view/1" do
    test "renders without errors" do
      state = %{view: :welcome, quit_requested: false}

      # TermUI view returns a widget spec tuple
      result = Root.view(state)
      assert is_tuple(result)
      assert tuple_size(result) == 3
    end

    test "view output contains AshAdmin TUI title" do
      state = %{view: :welcome, quit_requested: false}

      view_spec = Root.view(state)

      # Convert view spec to string for inspection
      view_string = inspect(view_spec)

      assert view_string =~ "AshAdmin TUI"
    end

    test "view output contains quit hint" do
      state = %{view: :welcome, quit_requested: false}

      view_spec = Root.view(state)

      # Convert view spec to string for inspection
      view_string = inspect(view_spec)

      assert view_string =~ "quit"
    end

    test "view output contains welcome message" do
      state = %{view: :welcome, quit_requested: false}

      view_spec = Root.view(state)

      # Convert view spec to string for inspection
      view_string = inspect(view_spec)

      assert view_string =~ "Welcome"
    end

    test "view changes when quit is requested" do
      state_before = %{view: :welcome, quit_requested: false}
      state_after = %{view: :welcome, quit_requested: true}

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
    test "view creates bordered layout" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      view_string = inspect(view_spec)

      # Verify it uses Block widget (bordered container)
      assert view_string =~ "Block"

      # Verify it has Label widget for content
      assert view_string =~ "Label"
    end

    test "view includes keyboard shortcut hint" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      view_string = inspect(view_spec)

      # Verify keyboard hint content
      assert view_string =~ "'Q'"
      assert view_string =~ "quit"
    end
  end
end
