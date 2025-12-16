defmodule AshAdminTui.Views.DetailView do
  @moduledoc """
  Detail View Component for AshAdmin TUI.

  The detail view displays all attributes of a single record in a readable
  two-column format. It supports navigation to related records and provides
  action shortcuts.

  ## State Structure

  ```elixir
  %{
    resource: %{name: "User"},
    record: %{id: 1, name: "Alice", email: "alice@example.com", ...},
    relationships: %{posts: [%{id: 1, title: "Post 1"}, ...]},
    fields: ["id", "name", "email", ...],
    selected_field_idx: 0
  }
  ```

  ## Keyboard Navigation

  - Up/Down arrows: Navigate through fields and relationships
  - Enter: Navigate to related record (when on relationship field)
  - e: Edit record
  - d: Delete record
  - b/Esc: Back to list view
  - a: Show actions for record

  ## Field Types

  - Strings: Display as-is with wrapping
  - Numbers: Right-aligned with formatting
  - Dates: YYYY-MM-DD format
  - Datetimes: YYYY-MM-DD HH:MM:SS UTC format
  - Booleans: Yes/No with color coding
  - Relationships: Related record identifier with → indicator
  """

  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack, HStack}

  @doc """
  Initializes the detail view with mock data for a specific record.

  Loads mock record data for the given resource and record ID.

  ## Examples

      iex> state = AshAdminTui.Views.DetailView.init(resource: "User", record_id: 1)
      iex> state.resource.name
      "User"
      iex> state.record["id"]
      1
      iex> state.selected_field_idx
      0
  """
  @spec init(keyword()) :: map()
  def init(opts) do
    resource_name = Keyword.get(opts, :resource, "Resource")
    record_id = Keyword.get(opts, :record_id, 1)

    # Load mock data
    record = load_mock_record(resource_name, record_id)
    relationships = load_mock_relationships(resource_name, record_id)
    fields = get_fields_for_resource(resource_name)

    %{
      resource: %{name: resource_name},
      record: record,
      relationships: relationships,
      fields: fields,
      selected_field_idx: 0
    }
  end

  @doc """
  Converts terminal events to navigation and action messages.

  Maps keyboard events to detail view navigation and action messages.
  """
  @spec event_to_msg(Event.t(), map()) :: {:msg, any()} | :ignore
  # Navigation - Arrow keys
  def event_to_msg(%Event.Key{key: :arrow_down}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :arrow_up}, _state), do: {:msg, {:move_selection, :up}}

  # Navigation - Home/End
  def event_to_msg(%Event.Key{key: :home}, _state), do: {:msg, {:move_selection, :home}}
  def event_to_msg(%Event.Key{key: :end}, _state), do: {:msg, {:move_selection, :end}}

  # Vim-style navigation
  def event_to_msg(%Event.Key{key: :char, char: "j"}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :char, char: "k"}, _state), do: {:msg, {:move_selection, :up}}

  # Actions - Navigate to related record
  def event_to_msg(%Event.Key{key: :enter}, state) do
    # Check if currently selected field is a relationship
    total_fields = length(state.fields)

    if state.selected_field_idx >= total_fields do
      # In relationships section
      relationship_idx = state.selected_field_idx - total_fields
      relationship_names = Map.keys(state.relationships)

      if relationship_idx < length(relationship_names) do
        relationship_name = Enum.at(relationship_names, relationship_idx)
        related_records = Map.get(state.relationships, relationship_name, [])

        # Use pattern matching instead of length check for better performance
        case related_records do
          [first_related | _] ->
            {:msg, {:navigate_to_related, relationship_name, first_related.id}}
          [] ->
            :ignore
        end
      else
        :ignore
      end
    else
      :ignore
    end
  end

  # Actions - Edit record
  def event_to_msg(%Event.Key{key: :char, char: "e"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:edit_record, Map.get(state.record, "id")}}
  end

  def event_to_msg(%Event.Key{key: :char, char: "E"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:edit_record, Map.get(state.record, "id")}}
  end

  # Actions - Delete record
  def event_to_msg(%Event.Key{key: :char, char: "d"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:delete_record, Map.get(state.record, "id")}}
  end

  def event_to_msg(%Event.Key{key: :char, char: "D"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:delete_record, Map.get(state.record, "id")}}
  end

  # Actions - Back to list
  def event_to_msg(%Event.Key{key: :char, char: "b"}, _state) do
    {:msg, :back_to_list}
  end

  def event_to_msg(%Event.Key{key: :char, char: "B"}, _state) do
    {:msg, :back_to_list}
  end

  def event_to_msg(%Event.Key{key: :escape}, _state) do
    {:msg, :back_to_list}
  end

  # Actions - Show actions
  def event_to_msg(%Event.Key{key: :char, char: "a"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:show_actions, Map.get(state.record, "id")}}
  end

  def event_to_msg(%Event.Key{key: :char, char: "A"}, state) do
    # Use string keys to avoid atom table exhaustion
    {:msg, {:show_actions, Map.get(state.record, "id")}}
  end

  def event_to_msg(_event, _state), do: :ignore

  @doc """
  Updates detail view state based on messages.

  Handles navigation and returns messages to parent component.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update({:move_selection, direction}, state) do
    total_items = length(state.fields) + map_size(state.relationships)
    max_index = max(total_items - 1, 0)

    new_index = case direction do
      :down ->
        if state.selected_field_idx >= max_index do
          0  # Wrap to top
        else
          state.selected_field_idx + 1
        end

      :up ->
        if state.selected_field_idx <= 0 do
          max_index  # Wrap to bottom
        else
          state.selected_field_idx - 1
        end

      :home ->
        0

      :end ->
        max_index
    end

    {%{state | selected_field_idx: new_index}, []}
  end

  def update({:navigate_to_related, resource, record_id}, state) do
    # Send message to parent component
    {state, [{:parent_msg, {:navigate_to_related, resource, record_id}}]}
  end

  def update({:edit_record, record_id}, state) do
    {state, [{:parent_msg, {:edit_record, state.resource.name, record_id}}]}
  end

  def update({:delete_record, record_id}, state) do
    {state, [{:parent_msg, {:delete_record, state.resource.name, record_id}}]}
  end

  def update(:back_to_list, state) do
    {state, [{:parent_msg, {:back_to_list, state.resource.name}}]}
  end

  def update({:show_actions, record_id}, state) do
    {state, [{:parent_msg, {:show_actions, state.resource.name, record_id}}]}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the detail view with title, fields, relationships, and footer.

  Displays record details in a two-column format with field navigation.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    {VStack, %{}, [
      render_title(state),
      render_attributes(state),
      render_relationships(state),
      render_footer(state)
    ]}
  end

  # Private helper functions

  defp render_title(state) do
    # Use string keys to avoid atom table exhaustion
    record_id = Map.get(state.record, "id")
    title = "#{state.resource.name} ##{record_id}"
    {Label, %{text: title, style: :bold}}
  end

  defp render_attributes(state) do
    rows = state.fields
    |> Enum.with_index()
    |> Enum.map(fn {field, index} ->
      render_field_row(field, state.record, index == state.selected_field_idx)
    end)

    {VStack, %{}, [
      {Label, %{text: "Attributes:", style: :bold}},
      {VStack, %{}, rows}
    ]}
  end

  defp render_field_row(field_name, record, selected) do
    # Use string keys to avoid atom table exhaustion
    value = Map.get(record, field_name, nil)
    formatted_value = format_field(field_name, value)

    style = if selected, do: :reverse, else: :normal

    # Two-column layout: field name | value
    {HStack, %{}, [
      {Label, %{text: String.pad_trailing("#{field_name}:", 20), style: style}},
      {Label, %{text: formatted_value, style: style}}
    ]}
  end

  defp render_relationships(state) do
    # Use Enum.empty? instead of map_size for better performance
    if Enum.empty?(state.relationships) do
      {Label, %{text: "", style: :normal}}
    else
      total_fields = length(state.fields)

      rows = state.relationships
      |> Enum.with_index()
      |> Enum.map(fn {{relationship_name, related_records}, index} ->
        selected = (total_fields + index) == state.selected_field_idx
        render_relationship_row(relationship_name, related_records, selected)
      end)

      {VStack, %{}, [
        {Label, %{text: "", style: :normal}},  # Blank line separator
        {Label, %{text: "Relationships:", style: :bold}},
        {VStack, %{}, rows}
      ]}
    end
  end

  defp render_relationship_row(relationship_name, related_records, selected) do
    style = if selected, do: :reverse, else: :normal

    # Use pattern matching instead of length check for better performance
    display = case related_records do
      [] ->
        "(none)"
      [first_record | rest] ->
        identifier = get_relationship_identifier(first_record)
        count = length(rest) + 1
        suffix = if count > 1, do: " (+#{count - 1} more)", else: ""
        "→ #{identifier}#{suffix}"
    end

    {HStack, %{}, [
      {Label, %{text: String.pad_trailing("#{relationship_name}:", 20), style: style}},
      {Label, %{text: display, style: style}}
    ]}
  end

  defp render_footer(_state) do
    footer_text = "[E]dit [D]elete [B]ack [A]ctions [Enter] Navigate to Related"
    {Label, %{text: footer_text, style: :dim}}
  end

  @doc """
  Formats a field value based on its type.

  Handles different data types with appropriate formatting and styling.
  """
  @spec format_field(String.t(), any()) :: String.t()
  def format_field(_field_name, value) when is_binary(value), do: value

  def format_field(_field_name, value) when is_integer(value) do
    # Right-align with thousand separators
    value
    |> Integer.to_string()
    |> add_thousand_separators()
  end

  def format_field(_field_name, value) when is_float(value) do
    Float.to_string(value)
  end

  def format_field(_field_name, value) when is_boolean(value) do
    if value, do: "Yes", else: "No"
  end

  def format_field(_field_name, %Date{} = value) do
    Date.to_string(value)
  end

  def format_field(_field_name, %DateTime{} = value) do
    datetime_string = DateTime.to_string(value)
    # Format as "YYYY-MM-DD HH:MM:SS UTC"
    datetime_string
  end

  def format_field(_field_name, %NaiveDateTime{} = value) do
    NaiveDateTime.to_string(value)
  end

  def format_field(_field_name, nil), do: ""

  def format_field(_field_name, value), do: inspect(value)

  defp add_thousand_separators(string) do
    string
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp get_relationship_identifier(record) do
    cond do
      Map.has_key?(record, :title) -> record.title
      Map.has_key?(record, :name) -> record.name
      Map.has_key?(record, :id) -> "##{record.id}"
      true -> inspect(record)
    end
  end

  # Mock data generators

  defp load_mock_record("User", record_id) do
    # Use string keys to avoid atom table exhaustion
    %{
      "id" => record_id,
      "name" => "User #{record_id}",
      "email" => "user#{record_id}@example.com",
      "active" => rem(record_id, 2) == 0,
      "created_at" => ~D[2024-01-15],
      "last_login" => ~U[2024-12-01 10:30:00Z],
      "post_count" => record_id * 5
    }
  end

  defp load_mock_record("Post", record_id) do
    # Generate a date based on record_id
    day = rem(record_id, 28) + 1
    date_string = "2024-11-#{String.pad_leading(Integer.to_string(day), 2, "0")}T14:30:00Z"
    {:ok, published_at, 0} = DateTime.from_iso8601(date_string)

    # Use string keys to avoid atom table exhaustion
    %{
      "id" => record_id,
      "title" => "Post #{record_id}",
      "body" => "This is the body text for post number #{record_id}. It contains some sample content to demonstrate text wrapping.",
      "status" => Enum.random(["draft", "published", "archived"]),
      "views" => record_id * 100,
      "published_at" => published_at,
      "is_featured" => rem(record_id, 3) == 0
    }
  end

  defp load_mock_record(_resource, record_id) do
    # Use string keys to avoid atom table exhaustion
    %{
      "id" => record_id,
      "name" => "Record #{record_id}",
      "description" => "Sample record for testing",
      "created_at" => ~D[2024-01-01],
      "updated_at" => ~U[2024-12-15 08:00:00Z]
    }
  end

  defp load_mock_relationships("User", user_id) do
    %{
      posts: [
        %{id: user_id * 10, title: "First Post by User #{user_id}"},
        %{id: user_id * 10 + 1, title: "Second Post by User #{user_id}"},
        %{id: user_id * 10 + 2, title: "Third Post by User #{user_id}"}
      ]
    }
  end

  defp load_mock_relationships("Post", post_id) do
    user_id = div(post_id, 10) + 1

    %{
      author: [
        %{id: user_id, name: "User #{user_id}"}
      ],
      comments: [
        %{id: post_id * 100, title: "Comment 1 on Post #{post_id}"},
        %{id: post_id * 100 + 1, title: "Comment 2 on Post #{post_id}"}
      ]
    }
  end

  defp load_mock_relationships(_resource, _record_id) do
    %{}
  end

  defp get_fields_for_resource("User") do
    ["id", "name", "email", "active", "created_at", "last_login", "post_count"]
  end

  defp get_fields_for_resource("Post") do
    ["id", "title", "body", "status", "views", "published_at", "is_featured"]
  end

  defp get_fields_for_resource(_) do
    ["id", "name", "description", "created_at", "updated_at"]
  end
end
