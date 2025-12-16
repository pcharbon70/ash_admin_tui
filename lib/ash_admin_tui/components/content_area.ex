defmodule AshAdminTui.Components.ContentArea do
  @moduledoc """
  Content Area Router Component for AshAdmin TUI.

  The content area router switches between different view types based on application
  state. It manages view-specific state isolation and coordinates view transitions
  with loading states.

  ## View Types

  - `:list` - Table view of records for a resource
  - `:detail` - Detailed view of a single record
  - `:form` - Form for creating or editing a record
  - `:action` - Action execution interface
  - `:loading` - Loading spinner during view transitions
  - `:error` - Error message display
  - `nil` - No view selected (welcome screen)

  ## State Structure

  ```elixir
  %{
    view_type: :list | :detail | :form | :action | :loading | :error | nil,
    view_states: %{
      list: %{},      # ListView state
      detail: %{},    # DetailView state
      form: %{},      # FormView state
      action: %{}     # ActionView state
    },
    error_message: nil,
    loading_message: nil,
    previous_view: nil  # For preserving state when returning
  }
  ```

  ## View Transitions

  When transitioning to a new view:
  1. Set `view_type` to `:loading`
  2. Store current view in `previous_view`
  3. Return command to fetch data
  4. On data load, transition to target view
  5. On error, transition to `:error` view
  """

  alias AshAdminTui.Views.{DetailView, FormView, ListView}
  alias TermUI.Widget.{Label, VStack}

  @doc """
  Initializes the content area with no active view.

  Returns initial state with welcome screen.

  ## Examples

      iex> state = AshAdminTui.Components.ContentArea.init([])
      iex> state.view_type
      nil
      iex> state.view_states
      %{list: %{}, detail: %{}, form: %{}, action: %{}}
  """
  @spec init(keyword()) :: map()
  def init(_opts) do
    %{
      view_type: nil,
      view_states: %{
        list: %{},
        detail: %{},
        form: %{},
        action: %{}
      },
      error_message: nil,
      loading_message: nil,
      previous_view: nil
    }
  end

  @doc """
  Renders the current view based on view_type.

  Routes to appropriate view component or shows loading/error states.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(%{view_type: nil} = _state) do
    render_welcome()
  end

  def view(%{view_type: :loading, loading_message: message} = _state) do
    render_loading(message)
  end

  def view(%{view_type: :error, error_message: message} = _state) do
    render_error(message)
  end

  def view(%{view_type: :list, view_states: %{list: list_state}} = _state) do
    render_list_view(list_state)
  end

  def view(%{view_type: :detail, view_states: %{detail: detail_state}} = _state) do
    render_detail_view(detail_state)
  end

  def view(%{view_type: :form, view_states: %{form: form_state}} = _state) do
    render_form_view(form_state)
  end

  def view(%{view_type: :action, view_states: %{action: action_state}} = _state) do
    render_action_view(action_state)
  end

  @doc """
  Initiates a view transition.

  Sets the view to loading state and returns a command to fetch data.
  Preserves the current view state for potential return.

  ## Examples

      iex> state = AshAdminTui.Components.ContentArea.init([])
      iex> {new_state, _commands} = AshAdminTui.Components.ContentArea.change_view(state, :list, %{resource: "User"})
      iex> new_state.view_type
      :loading
      iex> new_state.previous_view
      nil
  """
  @spec change_view(map(), atom(), map()) :: {map(), list()}
  def change_view(state, target_view, params) do
    loading_message = get_loading_message(target_view, params)

    new_state = %{state |
      view_type: :loading,
      loading_message: loading_message,
      previous_view: state.view_type
    }

    # Return command to fetch data for the target view
    commands = [{:fetch_view_data, target_view, params}]

    {new_state, commands}
  end

  @doc """
  Completes a view transition with loaded data.

  Transitions from loading state to the target view with data.
  """
  @spec complete_view_transition(map(), atom(), map()) :: {map(), list()}
  def complete_view_transition(state, target_view, view_data) do
    new_view_states = Map.put(state.view_states, target_view, view_data)

    new_state = %{state |
      view_type: target_view,
      view_states: new_view_states,
      loading_message: nil
    }

    {new_state, []}
  end

  @doc """
  Transitions to error state.

  Shows error message and preserves previous view state.
  """
  @spec show_error(map(), String.t()) :: {map(), list()}
  def show_error(state, error_message) do
    new_state = %{state |
      view_type: :error,
      error_message: error_message,
      loading_message: nil
    }

    {new_state, []}
  end

  @doc """
  Returns to the previous view.

  Restores the previous view state, useful for canceling or going back.
  """
  @spec return_to_previous(map()) :: {map(), list()}
  def return_to_previous(%{previous_view: nil} = state) do
    # No previous view, return to welcome
    {%{state | view_type: nil, error_message: nil}, []}
  end

  def return_to_previous(%{previous_view: previous} = state) do
    new_state = %{state |
      view_type: previous,
      error_message: nil,
      loading_message: nil,
      previous_view: nil
    }

    {new_state, []}
  end

  @doc """
  Updates content area state based on messages.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update({:change_view, target_view, params}, state) do
    change_view(state, target_view, params)
  end

  def update({:view_data_loaded, target_view, view_data}, state) do
    complete_view_transition(state, target_view, view_data)
  end

  def update({:view_load_error, error_message}, state) do
    show_error(state, error_message)
  end

  def update(:return_to_previous, state) do
    return_to_previous(state)
  end

  def update(_msg, state) do
    {state, []}
  end

  # Private rendering functions

  defp render_welcome do
    {VStack, %{}, [
      {Label, %{
        text: """


        Welcome to AshAdmin TUI

        Select a resource from the sidebar to begin

        """,
        align: :center
      }}
    ]}
  end

  defp render_loading(message) do
    text = if message do
      """


      #{message}

      Loading...

      """
    else
      """


      Loading...

      """
    end

    {VStack, %{}, [
      {Label, %{
        text: text,
        align: :center
      }}
    ]}
  end

  defp render_error(message) do
    text = """


    Error

    #{message || "An error occurred"}

    Press 'b' to go back

    """

    {VStack, %{}, [
      {Label, %{
        text: text,
        align: :center,
        color: :red
      }}
    ]}
  end

  # View renderers - delegate to actual view components

  defp render_list_view(list_state) do
    ListView.view(list_state)
  end

  defp render_detail_view(detail_state) do
    DetailView.view(detail_state)
  end

  defp render_form_view(form_state) do
    FormView.view(form_state)
  end

  defp render_action_view(_state) do
    {VStack, %{}, [
      {Label, %{
        text: """


        [Action View]

        Action execution interface will be displayed here

        """,
        align: :center
      }}
    ]}
  end

  # Helper functions

  defp get_loading_message(:list, %{resource: resource}) do
    "Loading #{resource} records..."
  end

  defp get_loading_message(:detail, %{resource: resource, id: id}) do
    "Loading #{resource} ##{id}..."
  end

  defp get_loading_message(:form, %{resource: resource, mode: :new}) do
    "Preparing new #{resource} form..."
  end

  defp get_loading_message(:form, %{resource: resource, mode: :edit, id: id}) do
    "Loading #{resource} ##{id} for editing..."
  end

  defp get_loading_message(:action, %{resource: resource, action: action}) do
    "Preparing #{action} action for #{resource}..."
  end

  defp get_loading_message(_view, _params) do
    nil
  end
end
