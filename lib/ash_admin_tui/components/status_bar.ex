defmodule AshAdminTui.Components.StatusBar do
  @moduledoc """
  Status Bar Component for AshAdmin TUI.

  The status bar provides context-sensitive keyboard shortcut hints and displays
  transient toast notifications for success and error messages.

  ## Layout

  When showing shortcuts:
  ```
  [↑↓] Navigate [←→] Expand [Enter] Select [Q] Quit
  ```

  When showing toast:
  ```
  ✓ Record created successfully (dismissed in 3s)
  ```

  ## State

  The component expects a state map with the following keys:
  - `:focus` - Current focus (:sidebar, :content)
  - `:view` - Current view type (:list, :detail, :form, nil)
  - `:toast` - Toast state (nil or %{message, type, expires_at})
  - `:width` - Terminal width for formatting

  ## Toast Types

  - `:success` - Green text with checkmark (✓)
  - `:error` - Red text with cross (✗)
  """

  alias TermUI.Widget.Label

  @doc """
  Initializes the status bar state.

  Returns initial state with no active toast.

  ## Examples

      iex> AshAdminTui.Components.StatusBar.init([])
      %{toast: nil}
  """
  @spec init(keyword()) :: map()
  def init(_opts) do
    %{toast: nil}
  end

  @doc """
  Renders the status bar with shortcuts or toast message.

  When a toast is active, it displays the toast message instead of shortcuts.
  Otherwise, it shows context-appropriate keyboard shortcuts.

  ## Examples

      iex> state = %{focus: :sidebar, view: nil, toast: nil, width: 80}
      iex> {widget, props} = AshAdminTui.Components.StatusBar.view(state)
      iex> widget
      TermUI.Widget.Label
      iex> props.text =~ "Navigate"
      true
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(%{toast: toast} = _state) when not is_nil(toast) do
    render_toast(toast)
  end

  def view(state) do
    shortcuts = get_shortcuts(state.focus, state.view)
    {Label, %{text: shortcuts}}
  end

  @doc """
  Shows a toast notification.

  Returns updated state with toast scheduled to expire after the given duration.

  ## Examples

      iex> state = %{toast: nil}
      iex> new_state = AshAdminTui.Components.StatusBar.show_toast(state, "Record saved", :success, 3000)
      iex> new_state.toast.message
      "Record saved"
      iex> new_state.toast.type
      :success
  """
  @spec show_toast(map(), String.t(), :success | :error, non_neg_integer()) :: map()
  def show_toast(state, message, type, duration_ms) do
    expires_at = System.monotonic_time(:millisecond) + duration_ms

    %{state | toast: %{
      message: message,
      type: type,
      expires_at: expires_at,
      duration: duration_ms
    }}
  end

  @doc """
  Dismisses the currently active toast.

  ## Examples

      iex> state = %{toast: %{message: "Test", type: :success, expires_at: 12345, duration: 3000}}
      iex> new_state = AshAdminTui.Components.StatusBar.dismiss_toast(state)
      iex> new_state.toast
      nil
  """
  @spec dismiss_toast(map()) :: map()
  def dismiss_toast(state) do
    %{state | toast: nil}
  end

  @doc """
  Checks if the toast has expired and dismisses it if so.

  ## Examples

      iex> now = System.monotonic_time(:millisecond)
      iex> state = %{toast: %{message: "Test", type: :success, expires_at: now - 1000, duration: 3000}}
      iex> new_state = AshAdminTui.Components.StatusBar.check_toast_expiry(state)
      iex> new_state.toast
      nil
  """
  @spec check_toast_expiry(map()) :: map()
  def check_toast_expiry(%{toast: nil} = state), do: state

  def check_toast_expiry(%{toast: toast} = state) do
    now = System.monotonic_time(:millisecond)

    if now >= toast.expires_at do
      dismiss_toast(state)
    else
      state
    end
  end

  # Private helper functions

  defp render_toast(%{message: message, type: type, expires_at: expires_at, duration: _duration}) do
    icon = if type == :success, do: "✓", else: "✗"
    color = if type == :success, do: :green, else: :red

    # Calculate remaining seconds
    now = System.monotonic_time(:millisecond)
    remaining_ms = max(expires_at - now, 0)
    remaining_sec = div(remaining_ms + 999, 1000)  # Round up

    text = "#{icon} #{message} (dismissed in #{remaining_sec}s)"

    {Label, %{text: text, color: color}}
  end

  defp get_shortcuts(:sidebar, _view) do
    "[↑↓] Navigate [←→] Expand [Enter] Select [Tab] Switch Focus [Q] Quit"
  end

  defp get_shortcuts(:content, :list) do
    "[↑↓] Navigate [Enter] View [N]ew [E]dit [D]elete [Tab] Switch Focus [Q] Quit"
  end

  defp get_shortcuts(:content, :detail) do
    "[E]dit [D]elete [B]ack [A]ctions [Tab] Switch Focus [Q] Quit"
  end

  defp get_shortcuts(:content, :form) do
    "[Tab] Next Field [Shift+Tab] Prev Field [F5] Submit [Esc] Cancel [Q] Quit"
  end

  defp get_shortcuts(:content, _view) do
    "[Tab] Switch Focus [Q] Quit"
  end

  defp get_shortcuts(_focus, _view) do
    "[Q] Quit"
  end
end
