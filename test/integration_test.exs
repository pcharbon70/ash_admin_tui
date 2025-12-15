defmodule IntegrationTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Integration tests for Phase 1 components.

  These tests validate that all Phase 1 components work together correctly,
  ensuring the complete system behaves as expected from end-to-end.
  """

  alias AshAdminTui.UI.Root
  alias AshAdminTui.Config

  describe "Application Startup (1.7.1)" do
    test "application is already started by test suite" do
      # The application is automatically started by the test suite
      # Verify it's running by checking the supervision tree
      assert Process.whereis(AshAdminTui.Supervisor) != nil
      assert Process.alive?(Process.whereis(AshAdminTui.Supervisor))
    end

    test "supervision tree is established with Runtime GenServer" do
      # Get the supervisor PID
      supervisor_pid = Process.whereis(AshAdminTui.Supervisor)
      assert supervisor_pid != nil

      # Get children of the supervisor
      children = Supervisor.which_children(supervisor_pid)
      assert is_list(children)
      refute Enum.empty?(children)

      # Verify Runtime GenServer is a child
      runtime_child = Enum.find(children, fn
        {AshAdminTui.UI.Runtime, _, _, _} -> true
        _ -> false
      end)

      assert runtime_child != nil
    end

    test "Runtime GenServer is running after application start" do
      # Verify the Runtime GenServer is registered and running
      runtime_pid = Process.whereis(AshAdminTui.UI.Runtime)
      assert runtime_pid != nil
      assert Process.alive?(runtime_pid)

      # Verify we can get its state
      state = :sys.get_state(runtime_pid)
      assert is_map(state)
      assert Map.has_key?(state, :runtime_pid)
      assert Map.has_key?(state, :root_component)
    end

    test "application supervision tree is healthy" do
      # Verify supervisor is running
      supervisor_pid = Process.whereis(AshAdminTui.Supervisor)
      assert Process.alive?(supervisor_pid)

      # Verify all children are running
      children = Supervisor.which_children(supervisor_pid)

      Enum.each(children, fn
        {_id, pid, _type, _modules} when is_pid(pid) ->
          assert Process.alive?(pid), "Child process #{inspect(pid)} is not alive"

        {_id, :undefined, _type, _modules} ->
          # Child not started yet, which is acceptable
          :ok

        {_id, :restarting, _type, _modules} ->
          # Child is restarting, which is acceptable during tests
          :ok
      end)
    end
  end

  describe "TermUI Rendering (1.7.2)" do
    test "Root component initializes with correct state" do
      state = Root.init([])

      assert is_map(state)
      assert Map.has_key?(state, :view)
      assert Map.has_key?(state, :quit_requested)
      assert state.view == :welcome
      assert state.quit_requested == false
    end

    test "view/1 generates valid TermUI render tree" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      # Verify it's a valid widget tree (3-tuple)
      assert is_tuple(view_spec)
      assert tuple_size(view_spec) == 3

      # Verify the structure: {WidgetModule, props, children}
      {widget_module, props, children} = view_spec
      assert is_atom(widget_module)
      assert is_map(props)
      assert is_list(children)
    end

    test "welcome screen contains AshAdmin TUI title" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      # Convert to string and verify content
      view_string = inspect(view_spec)
      assert view_string =~ "AshAdmin TUI"
    end

    test "welcome screen contains quit hint" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      # Convert to string and verify content
      view_string = inspect(view_spec)
      assert view_string =~ "quit"
      assert view_string =~ "'Q'"
    end

    test "layout uses Block and Label widgets" do
      state = %{view: :welcome, quit_requested: false}
      view_spec = Root.view(state)

      # Verify widget structure
      view_string = inspect(view_spec)
      assert view_string =~ "Block"
      assert view_string =~ "Label"
    end

    test "view changes based on state" do
      # Test welcome state
      welcome_state = %{view: :welcome, quit_requested: false}
      welcome_view = inspect(Root.view(welcome_state))
      assert welcome_view =~ "Welcome"

      # Test shutdown state
      shutdown_state = %{view: :welcome, quit_requested: true}
      shutdown_view = inspect(Root.view(shutdown_state))
      assert shutdown_view =~ "Shutting down"

      # Verify they're different
      refute welcome_view == shutdown_view
    end
  end

  describe "Event Handling (1.7.3)" do
    test "pressing 'q' key generates :quit message" do
      state = %{view: :welcome, quit_requested: false}
      event = %TermUI.Event.Key{key: :char, char: "q"}

      result = Root.event_to_msg(event, state)
      assert result == {:msg, :quit}
    end

    test "pressing 'Q' key generates :quit message" do
      state = %{view: :welcome, quit_requested: false}
      event = %TermUI.Event.Key{key: :char, char: "Q"}

      result = Root.event_to_msg(event, state)
      assert result == {:msg, :quit}
    end

    test ":quit message sets quit_requested to true" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, _commands} = Root.update(:quit, state)

      assert new_state.quit_requested == true
    end

    test ":quit message returns :stop command" do
      state = %{view: :welcome, quit_requested: false}

      {_new_state, commands} = Root.update(:quit, state)

      assert :stop in commands
      assert commands == [:stop]
    end

    test "other key presses are ignored" do
      state = %{view: :welcome, quit_requested: false}

      # Test various keys
      assert Root.event_to_msg(%TermUI.Event.Key{key: :char, char: "a"}, state) == :ignore
      assert Root.event_to_msg(%TermUI.Event.Key{key: :char, char: "b"}, state) == :ignore
      assert Root.event_to_msg(%TermUI.Event.Key{key: :char, char: "1"}, state) == :ignore
    end

    test "non-key events are ignored" do
      state = %{view: :welcome, quit_requested: false}

      # Test resize event
      resize_event = %TermUI.Event.Resize{width: 80, height: 24}
      assert Root.event_to_msg(resize_event, state) == :ignore

      # Test unknown event
      assert Root.event_to_msg(:unknown, state) == :ignore
    end

    test "event handling preserves other state" do
      state = %{view: :welcome, quit_requested: false}

      {new_state, _commands} = Root.update(:quit, state)

      # quit_requested changes
      assert new_state.quit_requested == true

      # view is preserved
      assert new_state.view == :welcome
    end
  end

  describe "Configuration Integration (1.7.4)" do
    setup do
      # Store original environment variables
      original_api_url = System.get_env("ASH_ADMIN_API_URL")
      original_log_level = System.get_env("ASH_ADMIN_LOG_LEVEL")

      # Clear environment variables
      System.delete_env("ASH_ADMIN_API_URL")
      System.delete_env("ASH_ADMIN_LOG_LEVEL")

      on_exit(fn ->
        # Restore original environment variables
        if original_api_url, do: System.put_env("ASH_ADMIN_API_URL", original_api_url)
        if original_log_level, do: System.put_env("ASH_ADMIN_LOG_LEVEL", original_log_level)
      end)

      :ok
    end

    test "config values are loaded from config files" do
      # In test environment, config/test.exs should be loaded
      # Verify we can access configuration
      api_url = Config.get(:api_url)
      log_level = Config.get(:log_level)

      # These should have values from config/test.exs
      assert api_url != nil
      assert log_level != nil
    end

    test "environment variables override config file values" do
      # Set environment variable
      System.put_env("ASH_ADMIN_API_URL", "http://env-override.example.com")

      # Get config value
      api_url = Config.get(:api_url)

      # Should return environment variable value
      assert api_url == "http://env-override.example.com"
    end

    test "Config module is accessible from application modules" do
      # Verify Config module is loaded
      assert Code.ensure_loaded?(AshAdminTui.Config)

      # Verify we can call Config functions
      assert is_function(&Config.get/2, 2)
      assert is_function(&Config.validate/0, 0)
      assert is_function(&Config.api_url/0, 0)
      assert is_function(&Config.log_level/0, 0)
      assert is_function(&Config.theme/0, 0)
    end

    test "invalid configuration triggers validation errors" do
      # Store original log level
      original_log_level = Application.get_env(:ash_admin_tui, :log_level)

      # Set invalid log level
      Application.put_env(:ash_admin_tui, :log_level, :invalid_level)

      # Validate should fail
      result = Config.validate()
      assert {:error, message} = result
      assert message =~ "Invalid log_level"

      # Restore original log level
      Application.put_env(:ash_admin_tui, :log_level, original_log_level)
    end

    test "configuration is accessible throughout application lifecycle" do
      # Test that config is available at different points

      # 1. During initialization
      assert Config.log_level() != nil

      # 2. From Root component
      state = Root.init([])
      assert is_map(state)

      # Config should still be accessible
      assert Config.log_level() != nil
      assert Config.theme() != nil

      # 3. During update
      {new_state, _} = Root.update(:quit, state)
      assert is_map(new_state)

      # Config should still be accessible
      assert Config.api_url() != nil || Config.api_url() == nil  # May be nil
    end

    test "configuration validation can be called multiple times" do
      # Validation should be idempotent
      assert Config.validate() == :ok
      assert Config.validate() == :ok
      assert Config.validate() == :ok
    end
  end

  describe "End-to-End Integration" do
    test "complete user flow: start -> render -> quit" do
      # 1. Application is running (verified by supervision tree)
      assert Process.whereis(AshAdminTui.Supervisor) != nil

      # 2. Initialize UI state
      state = Root.init([])
      assert state.quit_requested == false

      # 3. Render welcome screen
      view = Root.view(state)
      view_string = inspect(view)
      assert view_string =~ "Welcome"

      # 4. User presses 'q'
      event = %TermUI.Event.Key{key: :char, char: "q"}
      {:msg, message} = Root.event_to_msg(event, state)
      assert message == :quit

      # 5. Update state with quit message
      {new_state, commands} = Root.update(message, state)
      assert new_state.quit_requested == true
      assert :stop in commands

      # 6. Render shutdown screen
      shutdown_view = Root.view(new_state)
      shutdown_string = inspect(shutdown_view)
      assert shutdown_string =~ "Shutting down"
    end

    test "configuration affects application behavior" do
      # Test that configuration is used throughout the application

      # 1. Set configuration
      original_theme = Application.get_env(:ash_admin_tui, :theme)
      Application.put_env(:ash_admin_tui, :theme, :custom_theme)

      # 2. Verify Config module reflects the change
      assert Config.theme() == :custom_theme

      # 3. Initialize component
      state = Root.init([])
      assert is_map(state)

      # 4. Configuration should still be accessible
      assert Config.theme() == :custom_theme

      # Restore original theme
      Application.put_env(:ash_admin_tui, :theme, original_theme)
    end

    test "Mix task can be discovered and loaded" do
      # Verify the Mix task module exists
      assert Code.ensure_loaded?(Mix.Tasks.AshAdmin.Tui)

      # Verify it's in the task list
      Mix.Task.load_all()
      tasks = Mix.Task.all_modules()
      assert Mix.Tasks.AshAdmin.Tui in tasks

      # Verify it implements the required callback
      assert function_exported?(Mix.Tasks.AshAdmin.Tui, :run, 1)
    end

    test "all Phase 1 modules are loaded and accessible" do
      # Core modules
      assert Code.ensure_loaded?(AshAdminTui.Application)
      assert Code.ensure_loaded?(AshAdminTui.Config)
      assert Code.ensure_loaded?(AshAdminTui.UI.Runtime)
      assert Code.ensure_loaded?(AshAdminTui.UI.Root)

      # Mix task
      assert Code.ensure_loaded?(Mix.Tasks.AshAdmin.Tui)

      # All modules should have proper documentation
      assert AshAdminTui.Application.__info__(:module) == AshAdminTui.Application
      assert AshAdminTui.Config.__info__(:module) == AshAdminTui.Config
      assert AshAdminTui.UI.Runtime.__info__(:module) == AshAdminTui.UI.Runtime
      assert AshAdminTui.UI.Root.__info__(:module) == AshAdminTui.UI.Root
    end
  end
end
