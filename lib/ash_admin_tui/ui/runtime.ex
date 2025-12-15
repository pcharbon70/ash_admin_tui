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

    # For now, we'll initialize with a simple state
    # The actual TermUI.Runtime integration will be added in Section 1.4
    # when we implement the root component
    state = %{
      runtime_pid: nil,
      root_component: nil,
      started_at: DateTime.utc_now()
    }

    Logger.info("AshAdmin TUI Runtime initialized (TermUI integration pending)")

    {:ok, state}
  end

  @impl true
  def handle_info({:term_ui, _msg} = message, state) do
    # Forward TermUI messages to the runtime
    # This will be fully implemented in Section 1.4
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

    # Graceful TermUI shutdown will be implemented in Section 1.4
    # For now, we just log the shutdown
    if state.runtime_pid do
      Logger.debug("Stopping TermUI runtime process: #{inspect(state.runtime_pid)}")
    end

    :ok
  end
end
