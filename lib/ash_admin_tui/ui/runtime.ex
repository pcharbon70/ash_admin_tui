defmodule AshAdminTui.UI.Runtime do
  @moduledoc """
  GenServer wrapper for TermUI.Runtime providing OTP supervision integration.

  This module wraps TermUI.Runtime to integrate it with OTP's supervision tree,
  enabling process monitoring, crash recovery, and graceful shutdown. The GenServer
  manages the lifecycle of the TermUI application while maintaining the Elm Architecture
  pattern used by TermUI.

  ## Lifecycle

  - `init/1` - Starts TermUI.Runtime with the root component
  - `handle_info/2` - Forwards TermUI messages to the runtime
  - `terminate/2` - Ensures graceful shutdown of TermUI
  """

  use GenServer
  require Logger

  @doc """
  Starts the Runtime GenServer.

  ## Options

  - `:name` - The registered name for the GenServer (default: __MODULE__)
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Returns the child specification for supervision.

  The Runtime is configured with:
  - Unique `:id` for the supervision tree
  - `:permanent` restart strategy (always restart on failure)
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000,
      type: :worker
    }
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting AshAdmin TUI Runtime...")

    # Start TermUI.Runtime with the Root component
    case TermUI.Runtime.start_link(root: AshAdminTui.UI.Root) do
      {:ok, runtime_pid} ->
        Logger.info("AshAdmin TUI Runtime initialized successfully")

        state = %{
          runtime_pid: runtime_pid,
          root_component: AshAdminTui.UI.Root,
          started_at: DateTime.utc_now()
        }

        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to start TermUI.Runtime: #{inspect(reason)}")
        {:stop, {:termui_start_failed, reason}}
    end
  end

  @impl true
  def handle_info({:term_ui, _msg} = message, state) do
    # TermUI messages are handled directly by the TermUI.Runtime process
    # This GenServer wrapper receives these messages for monitoring and logging
    # Future phases may add custom message handling for specific events
    Logger.debug("Received TermUI message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    Logger.debug("Received unexpected message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Shutting down AshAdmin TUI Runtime: #{inspect(reason)}")

    # The TermUI runtime is linked to this process via start_link, so it will
    # automatically terminate when this process terminates. We don't need to
    # explicitly stop it, and doing so can cause race conditions with its own
    # cleanup logic.
    if state.runtime_pid && Process.alive?(state.runtime_pid) do
      Logger.debug("TermUI runtime process #{inspect(state.runtime_pid)} will terminate via link")
    end

    :ok
  end
end
