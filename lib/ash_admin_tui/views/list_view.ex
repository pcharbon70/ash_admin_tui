defmodule AshAdminTui.Views.ListView do
  @moduledoc """
  List View Component for AshAdmin TUI.

  The list view displays records in a table format with sorting, pagination,
  and row selection. It handles keyboard navigation for scrolling and selection.

  ## State Structure

  ```elixir
  %{
    resource: %{name: "User", columns: ["id", "name", "email"]},
    records: [%{id: 1, name: "Alice", email: "alice@example.com"}, ...],
    columns: ["id", "name", "email"],
    selected_row: 0,
    sort: %{column: "id", direction: :asc},
    page: 1,
    page_size: 10,
    total: 100
  }
  ```

  ## Keyboard Navigation

  - Up/Down arrows: Navigate through rows
  - PgUp/PgDown: Navigate by page
  - Home/End: Jump to first/last row
  - Enter: View detail of selected record
  - n: Create new record
  - e: Edit selected record
  - d: Delete selected record
  - a: Show actions for selected record

  ## Selection

  - Selection wraps at boundaries
  - Selected row is highlighted
  - Footer shows pagination info
  """

  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack, HStack}

  @page_size 10

  @doc """
  Initializes the list view with mock data.

  Creates initial state with 10 sample records for the given resource.

  ## Examples

      iex> state = AshAdminTui.Views.ListView.init(resource: "User")
      iex> state.resource.name
      "User"
      iex> length(state.records)
      10
      iex> state.selected_row
      0
  """
  @spec init(keyword()) :: map()
  def init(opts) do
    resource_name = Keyword.get(opts, :resource, "Resource")

    # Mock data - will be replaced with real Ash data in Phase 3
    records = generate_mock_records(resource_name, @page_size)
    columns = get_columns_for_resource(resource_name)

    %{
      resource: %{name: resource_name, columns: columns},
      records: records,
      columns: columns,
      selected_row: 0,
      sort: %{column: Enum.at(columns, 0), direction: :asc},
      page: 1,
      page_size: @page_size,
      total: 42  # Mock total
    }
  end

  @doc """
  Converts terminal events to navigation messages.

  Maps keyboard events to list navigation and action messages.
  """
  @spec event_to_msg(Event.t(), map()) :: {:msg, any()} | :ignore
  # Navigation - Arrow keys
  def event_to_msg(%Event.Key{key: :arrow_down}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :arrow_up}, _state), do: {:msg, {:move_selection, :up}}

  # Navigation - Page keys
  def event_to_msg(%Event.Key{key: :page_down}, _state), do: {:msg, {:move_selection, :page_down}}
  def event_to_msg(%Event.Key{key: :page_up}, _state), do: {:msg, {:move_selection, :page_up}}

  # Navigation - Home/End
  def event_to_msg(%Event.Key{key: :home}, _state), do: {:msg, {:move_selection, :home}}
  def event_to_msg(%Event.Key{key: :end}, _state), do: {:msg, {:move_selection, :end}}

  # Vim-style navigation
  def event_to_msg(%Event.Key{key: :char, char: "j"}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :char, char: "k"}, _state), do: {:msg, {:move_selection, :up}}

  # Actions
  def event_to_msg(%Event.Key{key: :enter}, state) do
    with_selected_record_id(state, &{:view_detail, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "n"}, _state), do: {:msg, :new_record}
  def event_to_msg(%Event.Key{key: :char, char: "N"}, _state), do: {:msg, :new_record}

  def event_to_msg(%Event.Key{key: :char, char: "e"}, state) do
    with_selected_record_id(state, &{:edit_record, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "E"}, state) do
    with_selected_record_id(state, &{:edit_record, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "d"}, state) do
    with_selected_record_id(state, &{:delete_record, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "D"}, state) do
    with_selected_record_id(state, &{:delete_record, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "a"}, state) do
    with_selected_record_id(state, &{:show_actions, &1})
  end

  def event_to_msg(%Event.Key{key: :char, char: "A"}, state) do
    with_selected_record_id(state, &{:show_actions, &1})
  end

  def event_to_msg(_event, _state), do: :ignore

  @doc """
  Updates list view state based on messages.

  Handles navigation and returns messages to parent component.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update({:move_selection, direction}, state) do
    max_index = length(state.records) - 1

    new_index = case direction do
      :down ->
        if state.selected_row >= max_index do
          0  # Wrap to top
        else
          state.selected_row + 1
        end

      :up ->
        if state.selected_row <= 0 do
          max_index  # Wrap to bottom
        else
          state.selected_row - 1
        end

      :page_down ->
        min(state.selected_row + state.page_size, max_index)

      :page_up ->
        max(state.selected_row - state.page_size, 0)

      :home ->
        0

      :end ->
        max_index
    end

    {%{state | selected_row: new_index}, []}
  end

  def update({:view_detail, record_id}, state) do
    # Send message to parent component
    {state, [{:parent_msg, {:view_detail, state.resource.name, record_id}}]}
  end

  def update(:new_record, state) do
    {state, [{:parent_msg, {:new_record, state.resource.name}}]}
  end

  def update({:edit_record, record_id}, state) do
    {state, [{:parent_msg, {:edit_record, state.resource.name, record_id}}]}
  end

  def update({:delete_record, record_id}, state) do
    {state, [{:parent_msg, {:delete_record, state.resource.name, record_id}}]}
  end

  def update({:show_actions, record_id}, state) do
    {state, [{:parent_msg, {:show_actions, state.resource.name, record_id}}]}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the list view with table and footer.

  Displays records in a table-like format with column headers,
  selection highlighting, and pagination info in footer.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    {VStack, %{}, [
      render_header(state),
      render_rows(state),
      render_footer(state)
    ]}
  end

  # Private helper functions

  defp render_header(state) do
    # Create header row with column names
    column_labels = Enum.map(state.columns, fn col ->
      {Label, %{text: String.pad_trailing(String.capitalize(col), 15), style: :bold}}
    end)

    {HStack, %{}, column_labels}
  end

  defp render_rows(state) do
    rows = state.records
    |> Enum.with_index()
    |> Enum.map(fn {record, index} ->
      render_row(record, index == state.selected_row, state.columns)
    end)

    {VStack, %{}, rows}
  end

  defp render_row(record, selected, columns) do
    style = if selected, do: :reverse, else: :normal

    cells = Enum.map(columns, fn col ->
      # Use string keys to avoid atom table exhaustion
      value = Map.get(record, col, "")
      text = format_value(value)
      {Label, %{text: String.pad_trailing(text, 15), style: style}}
    end)

    {HStack, %{}, cells}
  end

  defp render_footer(state) do
    # Calculate pagination info
    first_record = (state.page - 1) * state.page_size + 1
    last_record = min(state.page * state.page_size, state.total)
    total_pages = ceil(state.total / state.page_size)

    footer_text = "Page #{state.page} of #{total_pages} | Records #{first_record}-#{last_record} of #{state.total} | [N]ew [E]dit [D]elete [A]ctions [Enter] View"

    {Label, %{text: footer_text, style: :dim}}
  end

  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_integer(value), do: Integer.to_string(value)
  defp format_value(value) when is_float(value), do: Float.to_string(value)
  defp format_value(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  defp format_value(nil), do: ""
  defp format_value(value), do: inspect(value)

  # Selected record helpers

  # Helper function to get selected record and extract its ID for actions.
  # Reduces code duplication and ensures consistent string key access.
  defp with_selected_record_id(state, msg_builder) when is_function(msg_builder, 1) do
    case get_selected_record(state) do
      nil -> :ignore
      record -> {:msg, msg_builder.(Map.get(record, "id"))}
    end
  end

  # Gets the currently selected record from state, or nil if none selected.
  defp get_selected_record(state) do
    Enum.at(state.records, state.selected_row)
  end

  # Mock data generators

  defp generate_mock_records("User", count) do
    for i <- 1..count do
      # Use string keys to avoid atom table exhaustion
      %{
        "id" => i,
        "name" => "User #{i}",
        "email" => "user#{i}@example.com",
        "active" => rem(i, 2) == 0
      }
    end
  end

  defp generate_mock_records("Post", count) do
    for i <- 1..count do
      # Use string keys to avoid atom table exhaustion
      %{
        "id" => i,
        "title" => "Post #{i}",
        "status" => Enum.random(["draft", "published", "archived"]),
        "views" => i * 10
      }
    end
  end

  defp generate_mock_records(_resource, count) do
    for i <- 1..count do
      # Use string keys to avoid atom table exhaustion
      %{
        "id" => i,
        "name" => "Record #{i}",
        "created_at" => "2024-01-#{String.pad_leading(Integer.to_string(i), 2, "0")}"
      }
    end
  end

  defp get_columns_for_resource("User"), do: ["id", "name", "email", "active"]
  defp get_columns_for_resource("Post"), do: ["id", "title", "status", "views"]
  defp get_columns_for_resource(_), do: ["id", "name", "created_at"]
end
