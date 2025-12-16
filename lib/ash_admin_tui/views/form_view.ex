defmodule AshAdminTui.Views.FormView do
  @moduledoc """
  Form View Component for AshAdmin TUI.

  The form view provides create and edit forms with field validation and
  relationship selection. It dynamically generates form fields based on
  resource attributes.

  ## State Structure

  ```elixir
  %{
    resource: %{name: "User"},
    mode: :create | :edit,
    record_id: nil | integer(),
    form_values: %{name: "Alice", email: "alice@example.com"},
    errors: %{email: "is required"},
    focused_field_idx: 0,
    fields: ["name", "email", "active"],
    has_changes: false
  }
  ```

  ## Keyboard Navigation

  - Tab: Move focus to next field
  - Shift-Tab: Move focus to previous field
  - F5 or Ctrl-S: Submit form with validation
  - Esc: Cancel and go back (with confirmation if changes made)
  - Enter: Edit focused field value (mock)
  - Space: Toggle boolean fields

  ## Field Types

  For Phase 2, fields are represented with simple text labels:
  - Strings: [value here]
  - Numbers: [42]
  - Booleans: [x] or [ ]
  - Focused field: highlighted with reverse style

  Phase 3 will integrate with actual input widgets.
  """

  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack, HStack}

  @doc """
  Initializes the form view for create mode.

  Creates empty form with default values for all fields.

  ## Examples

      iex> state = AshAdminTui.Views.FormView.init(resource: "User", mode: :create)
      iex> state.resource.name
      "User"
      iex> state.mode
      :create
      iex> state.form_values
      %{}
  """
  @spec init(keyword()) :: map()
  def init(opts) do
    resource_name = Keyword.get(opts, :resource, "Resource")
    mode = Keyword.get(opts, :mode, :create)
    record_id = Keyword.get(opts, :record_id)

    fields = get_fields_for_resource(resource_name)

    form_values = case mode do
      :create -> %{}
      :edit -> load_record_values(resource_name, record_id)
    end

    %{
      resource: %{name: resource_name},
      mode: mode,
      record_id: record_id,
      form_values: form_values,
      errors: %{},
      focused_field_idx: 0,
      fields: fields,
      has_changes: false
    }
  end

  @doc """
  Converts terminal events to form navigation and action messages.

  Maps keyboard events to form field navigation and action messages.
  """
  @spec event_to_msg(Event.t(), map()) :: {:msg, any()} | :ignore
  # Navigation - Tab key (Phase 2: no shift detection, use arrows for reverse)
  def event_to_msg(%Event.Key{key: :char, char: "\t"}, _state) do
    {:msg, {:move_focus, :next}}
  end

  # Navigation - Arrow keys
  def event_to_msg(%Event.Key{key: :arrow_down}, _state), do: {:msg, {:move_focus, :next}}
  def event_to_msg(%Event.Key{key: :arrow_up}, _state), do: {:msg, {:move_focus, :previous}}

  # Actions - Submit (F5 - Ctrl key detection not available in Phase 2)
  def event_to_msg(%Event.Key{key: :f5}, _state), do: {:msg, :submit_form}

  # Actions - Cancel (Esc)
  def event_to_msg(%Event.Key{key: :escape}, state) do
    if state.has_changes do
      {:msg, :confirm_cancel}
    else
      {:msg, :cancel_form}
    end
  end

  # Field editing - Enter to edit field (mock action for Phase 2)
  def event_to_msg(%Event.Key{key: :enter}, state) do
    field_name = Enum.at(state.fields, state.focused_field_idx)
    if field_name do
      {:msg, {:edit_field, field_name}}
    else
      :ignore
    end
  end

  # Field editing - Space to toggle boolean fields
  def event_to_msg(%Event.Key{key: :char, char: " "}, state) do
    field_name = Enum.at(state.fields, state.focused_field_idx)
    field_type = get_field_type(state.resource.name, field_name)

    if field_type == :boolean do
      {:msg, {:toggle_boolean, field_name}}
    else
      :ignore
    end
  end

  # Character input (mock for Phase 2 - just marks as changed)
  def event_to_msg(%Event.Key{key: :char, char: char}, state) when char >= "a" and char <= "z" do
    field_name = Enum.at(state.fields, state.focused_field_idx)
    field_type = get_field_type(state.resource.name, field_name)

    if field_type == :string do
      {:msg, {:append_char, field_name, char}}
    else
      :ignore
    end
  end

  def event_to_msg(%Event.Key{key: :char, char: char}, state) when char >= "0" and char <= "9" do
    field_name = Enum.at(state.fields, state.focused_field_idx)
    field_type = get_field_type(state.resource.name, field_name)

    if field_type == :string do
      {:msg, {:append_char, field_name, char}}
    else
      :ignore
    end
  end

  # Backspace
  def event_to_msg(%Event.Key{key: :backspace}, state) do
    field_name = Enum.at(state.fields, state.focused_field_idx)
    if field_name do
      {:msg, {:backspace_field, field_name}}
    else
      :ignore
    end
  end

  def event_to_msg(_event, _state), do: :ignore

  @doc """
  Updates form view state based on messages.

  Handles navigation, field editing, validation, and submission.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update({:move_focus, direction}, state) do
    max_index = length(state.fields) - 1

    new_index = case direction do
      :next ->
        if state.focused_field_idx >= max_index do
          0  # Wrap to first field
        else
          state.focused_field_idx + 1
        end

      :previous ->
        if state.focused_field_idx <= 0 do
          max_index  # Wrap to last field
        else
          state.focused_field_idx - 1
        end
    end

    {%{state | focused_field_idx: new_index}, []}
  end

  def update({:edit_field, _field_name}, state) do
    # Mock field editing - in Phase 3 this would open a text input
    # For now, just mark as having changes
    {%{state | has_changes: true}, []}
  end

  def update({:toggle_boolean, field_name}, state) do
    # Use string keys to avoid atom table exhaustion
    current_value = Map.get(state.form_values, field_name, false)
    new_values = Map.put(state.form_values, field_name, !current_value)

    {%{state | form_values: new_values, has_changes: true}, []}
  end

  def update({:append_char, field_name, char}, state) do
    # Use string keys to avoid atom table exhaustion
    current_value = Map.get(state.form_values, field_name, "")
    current_str = to_string(current_value)
    new_value = current_str <> char
    new_values = Map.put(state.form_values, field_name, new_value)

    {%{state | form_values: new_values, has_changes: true}, []}
  end

  def update({:backspace_field, field_name}, state) do
    # Use string keys to avoid atom table exhaustion
    current_value = Map.get(state.form_values, field_name, "")
    current_str = to_string(current_value)

    new_value = if String.length(current_str) > 0 do
      String.slice(current_str, 0..-2//1)
    else
      ""
    end

    new_values = Map.put(state.form_values, field_name, new_value)

    {%{state | form_values: new_values, has_changes: true}, []}
  end

  def update(:submit_form, state) do
    # Validate form
    errors = validate_form(state.resource.name, state.form_values)

    # Use Enum.empty? instead of map_size for better performance
    if Enum.empty?(errors) do
      # No errors - submit to parent
      {state, [{:parent_msg, {:submit_form, state.mode, state.resource.name, state.record_id, state.form_values}}]}
    else
      # Has errors - update state to display them
      {%{state | errors: errors}, []}
    end
  end

  def update(:confirm_cancel, state) do
    # In Phase 3, this would show a confirmation dialog
    # For now, just send cancel message
    {state, [{:parent_msg, {:cancel_form, state.resource.name}}]}
  end

  def update(:cancel_form, state) do
    {state, [{:parent_msg, {:cancel_form, state.resource.name}}]}
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the form view with title, fields, errors, and footer.

  Displays form fields with labels, input representations, and validation errors.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    {VStack, %{}, [
      render_title(state),
      render_fields(state),
      render_footer(state)
    ]}
  end

  # Private helper functions

  defp render_title(state) do
    title = case state.mode do
      :create -> "Create #{state.resource.name}"
      :edit -> "Edit #{state.resource.name} ##{state.record_id}"
    end

    {Label, %{text: title, style: :bold}}
  end

  defp render_fields(state) do
    field_rows = state.fields
    |> Enum.with_index()
    |> Enum.flat_map(fn {field_name, index} ->
      focused = index == state.focused_field_idx
      # Use string keys to avoid atom table exhaustion
      error = Map.get(state.errors, field_name)

      field_row = render_field_row(state, field_name, focused)

      if error do
        error_row = render_error_row(error)
        [field_row, error_row]
      else
        [field_row]
      end
    end)

    {VStack, %{}, field_rows}
  end

  defp render_field_row(state, field_name, focused) do
    # Use string keys to avoid atom table exhaustion
    field_type = get_field_type(state.resource.name, field_name)
    value = Map.get(state.form_values, field_name)

    label_text = String.pad_trailing("#{field_name}:", 20)
    input_widget = render_input_widget(field_type, value, focused)

    {HStack, %{}, [
      {Label, %{text: label_text, style: :normal}},
      input_widget
    ]}
  end

  defp render_input_widget(:string, value, focused) do
    display_value = if value, do: to_string(value), else: ""
    text = "[#{display_value}]"
    style = if focused, do: :reverse, else: :normal

    {Label, %{text: text, style: style}}
  end

  defp render_input_widget(:boolean, value, focused) do
    checkbox = if value, do: "[x]", else: "[ ]"
    style = if focused, do: :reverse, else: :normal

    {Label, %{text: checkbox, style: style}}
  end

  defp render_input_widget(_type, value, focused) do
    display_value = if value, do: inspect(value), else: ""
    text = "[#{display_value}]"
    style = if focused, do: :reverse, else: :normal

    {Label, %{text: text, style: style}}
  end

  defp render_error_row(error_message) do
    {Label, %{text: "  Error: #{error_message}", style: :normal}}
  end

  defp render_footer(_state) do
    submit_key = "[F5]"
    cancel_key = "[Esc]"

    footer_text = "#{submit_key} Submit | #{cancel_key} Cancel | [Tab] Next Field | [Space] Toggle"

    {Label, %{text: footer_text, style: :dim}}
  end

  # Field metadata and validation

  # Helper function to validate required fields
  # Returns updated errors map if field is missing or empty
  defp validate_required(errors, form_values, field_name, error_message \\ "is required") do
    if !Map.has_key?(form_values, field_name) || Map.get(form_values, field_name) == "" do
      Map.put(errors, field_name, error_message)
    else
      errors
    end
  end

  defp get_fields_for_resource("User") do
    ["name", "email", "active"]
  end

  defp get_fields_for_resource("Post") do
    ["title", "body", "status", "is_featured"]
  end

  defp get_fields_for_resource(_) do
    ["name", "description", "active"]
  end

  defp get_field_type("User", "name"), do: :string
  defp get_field_type("User", "email"), do: :string
  defp get_field_type("User", "active"), do: :boolean

  defp get_field_type("Post", "title"), do: :string
  defp get_field_type("Post", "body"), do: :string
  defp get_field_type("Post", "status"), do: :string
  defp get_field_type("Post", "is_featured"), do: :boolean

  defp get_field_type(_resource, "name"), do: :string
  defp get_field_type(_resource, "description"), do: :string
  defp get_field_type(_resource, "active"), do: :boolean
  defp get_field_type(_resource, _field), do: :string

  defp validate_form("User", form_values) do
    # Use string keys to avoid atom table exhaustion
    %{}
    |> validate_required(form_values, "name")
    |> validate_required(form_values, "email")
  end

  defp validate_form("Post", form_values) do
    # Use string keys to avoid atom table exhaustion
    %{}
    |> validate_required(form_values, "title")
  end

  defp validate_form(_resource, _form_values) do
    # Generic validation - no required fields
    %{}
  end

  defp load_record_values("User", record_id) do
    # Use string keys to avoid atom table exhaustion
    %{
      "name" => "User #{record_id}",
      "email" => "user#{record_id}@example.com",
      "active" => rem(record_id, 2) == 0
    }
  end

  defp load_record_values("Post", record_id) do
    # Use string keys to avoid atom table exhaustion
    %{
      "title" => "Post #{record_id}",
      "body" => "Body text for post #{record_id}",
      "status" => "published",
      "is_featured" => rem(record_id, 3) == 0
    }
  end

  defp load_record_values(_resource, record_id) do
    # Use string keys to avoid atom table exhaustion
    %{
      "name" => "Record #{record_id}",
      "description" => "Description for record #{record_id}",
      "active" => true
    }
  end
end
