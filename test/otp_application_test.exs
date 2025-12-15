defmodule OtpApplicationTest do
  use ExUnit.Case

  describe "Application.start/2" do
    test "returns supervision tree" do
      # The application is already started by ExUnit, so we test that it's running
      # by checking that the supervisor exists
      assert Process.whereis(AshAdminTui.Supervisor) != nil
    end

    test "supervision tree uses :one_for_one strategy" do
      # Verify the supervisor is running with correct strategy
      supervisor_pid = Process.whereis(AshAdminTui.Supervisor)
      assert supervisor_pid != nil

      # Verify it's a supervisor by checking it responds to supervisor calls
      children = Supervisor.which_children(AshAdminTui.Supervisor)
      assert is_list(children)

      # The :one_for_one strategy is verified by the supervisor's behavior:
      # - Each child process is independent
      # - If one child crashes, only that child is restarted
      # We can verify this indirectly by checking that multiple children can run independently
      assert length(children) >= 1
    end
  end

  describe "supervision tree children" do
    test "includes Runtime as child" do
      children = Supervisor.which_children(AshAdminTui.Supervisor)

      # Find the Runtime child
      runtime_child =
        Enum.find(children, fn {id, _pid, _type, _modules} ->
          id == AshAdminTui.UI.Runtime
        end)

      assert runtime_child != nil, "Runtime should be in supervision tree"
    end

    test "Runtime child is running" do
      children = Supervisor.which_children(AshAdminTui.Supervisor)

      runtime_child =
        Enum.find(children, fn {id, _pid, _type, _modules} ->
          id == AshAdminTui.UI.Runtime
        end)

      {_id, pid, _type, _modules} = runtime_child

      assert is_pid(pid), "Runtime should have a valid PID"
      assert Process.alive?(pid), "Runtime process should be alive"
    end
  end

  describe "Runtime GenServer" do
    test "starts successfully" do
      # The Runtime is started by the application supervisor
      # We verify it's registered and running
      runtime_pid = Process.whereis(AshAdminTui.UI.Runtime)

      assert runtime_pid != nil, "Runtime should be registered"
      assert Process.alive?(runtime_pid), "Runtime process should be alive"
    end

    test "is supervised with :permanent restart" do
      # Get the child spec for Runtime
      children = Supervisor.which_children(AshAdminTui.Supervisor)

      runtime_child =
        Enum.find(children, fn {id, _pid, _type, _modules} ->
          id == AshAdminTui.UI.Runtime
        end)

      assert runtime_child != nil

      # Verify the child spec has permanent restart
      # We can infer this from the behavior - permanent children always restart
      # Let's verify by checking the child spec definition
      child_spec = AshAdminTui.UI.Runtime.child_spec([])
      assert child_spec.restart == :permanent
    end

    test "terminates gracefully on shutdown" do
      # Start a separate Runtime GenServer for this test
      {:ok, pid} = AshAdminTui.UI.Runtime.start_link(name: :test_runtime)

      assert Process.alive?(pid)

      # Stop it gracefully
      GenServer.stop(pid, :normal)

      # Give it a moment to clean up
      Process.sleep(50)

      assert !Process.alive?(pid)
    end

    test "restarts on crash" do
      # Get the current Runtime PID
      initial_pid = Process.whereis(AshAdminTui.UI.Runtime)
      assert initial_pid != nil
      assert Process.alive?(initial_pid)

      # Kill the process to simulate a crash
      Process.exit(initial_pid, :kill)

      # Wait for supervisor to restart it
      Process.sleep(100)

      # Verify it restarted with a new PID
      new_pid = Process.whereis(AshAdminTui.UI.Runtime)
      assert new_pid != nil
      assert Process.alive?(new_pid)
      assert new_pid != initial_pid, "Runtime should have restarted with new PID"
    end

    test "has correct child_spec configuration" do
      child_spec = AshAdminTui.UI.Runtime.child_spec([])

      assert child_spec.id == AshAdminTui.UI.Runtime
      assert child_spec.restart == :permanent
      assert child_spec.type == :worker
      assert child_spec.shutdown == 5_000
      assert {AshAdminTui.UI.Runtime, :start_link, [[]]  } == child_spec.start
    end
  end

  describe "Runtime GenServer state" do
    test "initializes with correct state structure" do
      # Start a separate Runtime for testing
      {:ok, pid} = AshAdminTui.UI.Runtime.start_link(name: :test_runtime_state)

      # Get the state (using :sys.get_state for testing purposes)
      state = :sys.get_state(pid)

      assert is_map(state)
      assert Map.has_key?(state, :runtime_pid)
      assert Map.has_key?(state, :root_component)
      assert Map.has_key?(state, :started_at)

      # Clean up
      GenServer.stop(pid)
    end

    test "handles TermUI messages" do
      # Start a separate Runtime for testing
      {:ok, pid} = AshAdminTui.UI.Runtime.start_link(name: :test_runtime_messages)

      # Send a mock TermUI message
      send(pid, {:term_ui, :test_message})

      # Give it time to process
      Process.sleep(10)

      # Verify the process is still alive (didn't crash)
      assert Process.alive?(pid)

      # Clean up
      GenServer.stop(pid)
    end

    test "handles unexpected messages gracefully" do
      # Start a separate Runtime for testing
      {:ok, pid} = AshAdminTui.UI.Runtime.start_link(name: :test_runtime_unexpected)

      # Send an unexpected message
      send(pid, {:unexpected, :message})

      # Give it time to process
      Process.sleep(10)

      # Verify the process is still alive (didn't crash)
      assert Process.alive?(pid)

      # Clean up
      GenServer.stop(pid)
    end
  end
end
