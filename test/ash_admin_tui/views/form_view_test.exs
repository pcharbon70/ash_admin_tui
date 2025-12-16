defmodule AshAdminTui.Views.FormViewTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Views.FormView

  alias AshAdminTui.Views.FormView
  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack, HStack}

  describe "init/1 - create mode" do
    test "initializes with empty form values for create mode" do
      state = FormView.init(resource: "User", mode: :create)

      assert state.resource.name == "User"
      assert state.mode == :create
      assert state.form_values == %{}
      assert state.errors == %{}
      assert state.focused_field_idx == 0
      assert state.has_changes == false
    end

    test "initializes with correct fields for User resource" do
      state = FormView.init(resource: "User", mode: :create)

      assert state.fields == ["name", "email", "active"]
    end

    test "initializes with correct fields for Post resource" do
      state = FormView.init(resource: "Post", mode: :create)

      assert state.fields == ["title", "body", "status", "is_featured"]
    end

    test "record_id is nil for create mode" do
      state = FormView.init(resource: "User", mode: :create)

      assert state.record_id == nil
    end
  end

  describe "init/1 - edit mode" do
    test "initializes with pre-populated values for edit mode" do
      state = FormView.init(resource: "User", mode: :edit, record_id: 5)

      assert state.resource.name == "User"
      assert state.mode == :edit
      assert state.record_id == 5
      # Form values use string keys to avoid atom table exhaustion
      assert state.form_values["name"] == "User 5"
      assert state.form_values["email"] == "user5@example.com"
      assert state.form_values["active"] == false  # odd number
      assert state.has_changes == false
    end

    test "loads values for Post resource in edit mode" do
      state = FormView.init(resource: "Post", mode: :edit, record_id: 2)

      # Form values use string keys to avoid atom table exhaustion
      assert state.form_values["title"] == "Post 2"
      assert state.form_values["body"] == "Body text for post 2"
      assert state.form_values["status"] == "published"
    end

    test "loads generic values for unknown resource in edit mode" do
      state = FormView.init(resource: "Unknown", mode: :edit, record_id: 3)

      # Form values use string keys to avoid atom table exhaustion
      assert state.form_values["name"] == "Record 3"
      assert state.form_values["description"] == "Description for record 3"
      assert state.form_values["active"] == true
    end
  end

  describe "view/1 - structure" do
    test "renders VStack with title, fields, and footer" do
      state = FormView.init(resource: "User", mode: :create)

      {widget, _props, children} = FormView.view(state)

      assert widget == VStack
      assert length(children) == 3  # title, fields, footer
    end

    test "renders title for create mode" do
      state = FormView.init(resource: "User", mode: :create)

      {VStack, _props, [title | _rest]} = FormView.view(state)
      {Label, props} = title

      assert props.text == "Create User"
      assert props.style == :bold
    end

    test "renders title for edit mode with record ID" do
      state = FormView.init(resource: "Post", mode: :edit, record_id: 42)

      {VStack, _props, [title | _rest]} = FormView.view(state)
      {Label, props} = title

      assert props.text == "Edit Post #42"
      assert props.style == :bold
    end

    test "renders all fields for resource" do
      state = FormView.init(resource: "User", mode: :create)

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # User has 3 fields (name, email, active)
      assert length(field_rows) == 3
    end

    test "renders footer with action shortcuts" do
      state = FormView.init(resource: "User", mode: :create)

      {VStack, _props, children} = FormView.view(state)
      footer = List.last(children)
      {Label, footer_props} = footer

      assert footer_props.style == :dim
      assert String.contains?(footer_props.text, "Submit")
      assert String.contains?(footer_props.text, "Cancel")
      assert String.contains?(footer_props.text, "Tab")
    end
  end

  describe "view/1 - field rendering" do
    test "field rows have two-column layout" do
      state = FormView.init(resource: "User", mode: :create)

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      first_row = hd(field_rows)
      {HStack, _row_props, cells} = first_row

      assert length(cells) == 2  # label and input

      # Check label
      {Label, label_props} = Enum.at(cells, 0)
      assert String.contains?(label_props.text, ":")

      # Check input widget (Label representing input)
      {Label, _input_props} = Enum.at(cells, 1)
    end

    test "string fields render with brackets" do
      state = FormView.init(resource: "User", mode: :edit, record_id: 1)

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # First field should be name (string type)
      first_row = hd(field_rows)
      {HStack, _row_props, [_label, input]} = first_row
      {Label, input_props} = input

      assert String.starts_with?(input_props.text, "[")
      assert String.ends_with?(input_props.text, "]")
      assert String.contains?(input_props.text, "User 1")
    end

    test "boolean fields render as checkboxes" do
      state = FormView.init(resource: "User", mode: :edit, record_id: 2)
      state = %{state | focused_field_idx: 2}  # Focus on 'active' field

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # Third field should be active (boolean type)
      active_row = Enum.at(field_rows, 2)
      {HStack, _row_props, [_label, input]} = active_row
      {Label, input_props} = input

      # Even record_id = checked
      assert input_props.text in ["[x]", "[ ]"]
    end

    test "focused field has reverse style" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      first_row = hd(field_rows)
      {HStack, _row_props, [_label, input]} = first_row
      {Label, input_props} = input

      assert input_props.style == :reverse
    end

    test "unfocused field has normal style" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      second_row = Enum.at(field_rows, 1)
      {HStack, _row_props, [_label, input]} = second_row
      {Label, input_props} = input

      assert input_props.style == :normal
    end
  end

  describe "view/1 - validation errors" do
    test "displays validation errors below fields" do
      state = FormView.init(resource: "User", mode: :create)
      # Errors use string keys to avoid atom table exhaustion
      state = %{state | errors: %{"email" => "is required"}}

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # Should have extra rows for errors
      # User has 3 fields, but with 1 error should have 4 rows (3 fields + 1 error)
      assert length(field_rows) == 4

      # Find the error row (should be after email field)
      error_row = Enum.at(field_rows, 2)  # After name and email fields
      {Label, error_props} = error_row

      assert String.contains?(error_props.text, "Error:")
      assert String.contains?(error_props.text, "is required")
    end

    test "no error rows when no validation errors" do
      state = FormView.init(resource: "User", mode: :create)

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # Should have exactly 3 rows for 3 fields (no errors)
      assert length(field_rows) == 3
    end

    test "multiple validation errors display correctly" do
      state = FormView.init(resource: "User", mode: :create)
      # Errors use string keys to avoid atom table exhaustion
      state = %{state | errors: %{"name" => "is required", "email" => "is required"}}

      {VStack, _props, [_title, fields | _rest]} = FormView.view(state)
      {VStack, _fields_props, field_rows} = fields

      # Should have 5 rows (3 fields + 2 errors)
      assert length(field_rows) == 5
    end
  end

  describe "event_to_msg/2 - navigation" do
    test "Tab key generates move_focus next message" do
      state = FormView.init(resource: "User", mode: :create)
      event = %Event.Key{key: :char, char: "\t"}

      assert FormView.event_to_msg(event, state) == {:msg, {:move_focus, :next}}
    end

    test "Down arrow generates move_focus next message" do
      state = FormView.init(resource: "User", mode: :create)
      event = %Event.Key{key: :arrow_down}

      assert FormView.event_to_msg(event, state) == {:msg, {:move_focus, :next}}
    end

    test "Up arrow generates move_focus previous message" do
      state = FormView.init(resource: "User", mode: :create)
      event = %Event.Key{key: :arrow_up}

      assert FormView.event_to_msg(event, state) == {:msg, {:move_focus, :previous}}
    end
  end

  describe "event_to_msg/2 - actions" do
    test "F5 key generates submit_form message" do
      state = FormView.init(resource: "User", mode: :create)
      event = %Event.Key{key: :f5}

      assert FormView.event_to_msg(event, state) == {:msg, :submit_form}
    end

    test "Esc generates cancel_form when no changes" do
      state = FormView.init(resource: "User", mode: :create)
      event = %Event.Key{key: :escape}

      assert FormView.event_to_msg(event, state) == {:msg, :cancel_form}
    end

    test "Esc generates confirm_cancel when has changes" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | has_changes: true}
      event = %Event.Key{key: :escape}

      assert FormView.event_to_msg(event, state) == {:msg, :confirm_cancel}
    end

    test "Enter generates edit_field message for focused field" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}
      event = %Event.Key{key: :enter}

      assert FormView.event_to_msg(event, state) == {:msg, {:edit_field, "name"}}
    end

    test "Space generates toggle_boolean for boolean fields" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 2}  # active field (boolean)
      event = %Event.Key{key: :char, char: " "}

      assert FormView.event_to_msg(event, state) == {:msg, {:toggle_boolean, "active"}}
    end

    test "Space is ignored for non-boolean fields" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}  # name field (string)
      event = %Event.Key{key: :char, char: " "}

      assert FormView.event_to_msg(event, state) == :ignore
    end
  end

  describe "event_to_msg/2 - field editing" do
    test "character input generates append_char for string fields" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}  # name field
      event = %Event.Key{key: :char, char: "a"}

      assert FormView.event_to_msg(event, state) == {:msg, {:append_char, "name", "a"}}
    end

    test "number input generates append_char for string fields" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}  # name field
      event = %Event.Key{key: :char, char: "5"}

      assert FormView.event_to_msg(event, state) == {:msg, {:append_char, "name", "5"}}
    end

    test "backspace generates backspace_field message" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}
      event = %Event.Key{key: :backspace}

      assert FormView.event_to_msg(event, state) == {:msg, {:backspace_field, "name"}}
    end
  end

  describe "update/2 - navigation" do
    test "move_focus next increments focused_field_idx" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}

      {new_state, _commands} = FormView.update({:move_focus, :next}, state)

      assert new_state.focused_field_idx == 1
    end

    test "move_focus previous decrements focused_field_idx" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 2}

      {new_state, _commands} = FormView.update({:move_focus, :previous}, state)

      assert new_state.focused_field_idx == 1
    end

    test "move_focus next wraps at end" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 2}  # Last field (active)

      {new_state, _commands} = FormView.update({:move_focus, :next}, state)

      assert new_state.focused_field_idx == 0
    end

    test "move_focus previous wraps at start" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | focused_field_idx: 0}

      {new_state, _commands} = FormView.update({:move_focus, :previous}, state)

      assert new_state.focused_field_idx == 2  # Last field
    end
  end

  describe "update/2 - field editing" do
    test "toggle_boolean toggles boolean field value" do
      state = FormView.init(resource: "User", mode: :create)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"active" => false}}

      {new_state, _commands} = FormView.update({:toggle_boolean, "active"}, state)

      assert new_state.form_values["active"] == true
      assert new_state.has_changes == true
    end

    test "toggle_boolean marks form as changed" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, _commands} = FormView.update({:toggle_boolean, "active"}, state)

      assert new_state.has_changes == true
    end

    test "append_char appends character to field value" do
      state = FormView.init(resource: "User", mode: :create)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"name" => "Alice"}}

      {new_state, _commands} = FormView.update({:append_char, "name", "x"}, state)

      assert new_state.form_values["name"] == "Alicex"
      assert new_state.has_changes == true
    end

    test "append_char creates new value for empty field" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, _commands} = FormView.update({:append_char, "name", "A"}, state)

      assert new_state.form_values["name"] == "A"
    end

    test "backspace_field removes last character" do
      state = FormView.init(resource: "User", mode: :create)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"name" => "Alice"}}

      {new_state, _commands} = FormView.update({:backspace_field, "name"}, state)

      assert new_state.form_values["name"] == "Alic"
      assert new_state.has_changes == true
    end

    test "backspace_field handles empty value" do
      state = FormView.init(resource: "User", mode: :create)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"name" => ""}}

      {new_state, _commands} = FormView.update({:backspace_field, "name"}, state)

      assert new_state.form_values["name"] == ""
    end

    test "edit_field marks form as changed" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, _commands} = FormView.update({:edit_field, "name"}, state)

      assert new_state.has_changes == true
    end
  end

  describe "update/2 - form submission" do
    test "submit_form with valid data generates parent message" do
      state = FormView.init(resource: "User", mode: :create)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"name" => "Alice", "email" => "alice@example.com"}}

      {new_state, commands} = FormView.update(:submit_form, state)

      assert new_state.errors == %{}
      assert commands == [{:parent_msg, {:submit_form, :create, "User", nil, %{"name" => "Alice", "email" => "alice@example.com"}}}]
    end

    test "submit_form with missing required fields shows errors" do
      state = FormView.init(resource: "User", mode: :create)
      state = %{state | form_values: %{}}

      {new_state, commands} = FormView.update(:submit_form, state)

      # Errors use string keys to avoid atom table exhaustion
      assert Map.has_key?(new_state.errors, "name")
      assert Map.has_key?(new_state.errors, "email")
      assert commands == []
    end

    test "submit_form in edit mode includes record_id" do
      state = FormView.init(resource: "User", mode: :edit, record_id: 5)
      # Form values use string keys to avoid atom table exhaustion
      state = %{state | form_values: %{"name" => "Bob", "email" => "bob@example.com"}}

      {new_state, commands} = FormView.update(:submit_form, state)

      assert new_state.errors == %{}
      assert [{:parent_msg, {:submit_form, :edit, "User", 5, _values}}] = commands
    end

    test "submit_form validates Post resource" do
      state = FormView.init(resource: "Post", mode: :create)
      state = %{state | form_values: %{}}  # Missing title

      {new_state, commands} = FormView.update(:submit_form, state)

      # Errors use string keys to avoid atom table exhaustion
      assert Map.has_key?(new_state.errors, "title")
      assert commands == []
    end
  end

  describe "update/2 - form cancellation" do
    test "cancel_form generates parent message" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, commands} = FormView.update(:cancel_form, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:cancel_form, "User"}}]
    end

    test "confirm_cancel generates parent message" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, commands} = FormView.update(:confirm_cancel, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:cancel_form, "User"}}]
    end

    test "unknown message returns unchanged state" do
      state = FormView.init(resource: "User", mode: :create)

      {new_state, commands} = FormView.update(:unknown_message, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "integration - complete flows" do
    test "create flow: navigate -> edit -> submit" do
      # Initialize create form
      state = FormView.init(resource: "User", mode: :create)
      assert state.focused_field_idx == 0

      # Navigate to next field
      {state, _} = FormView.update({:move_focus, :next}, state)
      assert state.focused_field_idx == 1

      # Edit field - form values use string keys
      {state, _} = FormView.update({:append_char, "email", "a"}, state)
      assert state.form_values["email"] == "a"
      assert state.has_changes == true

      # Add more characters
      {state, _} = FormView.update({:append_char, "email", "@"}, state)
      assert state.form_values["email"] == "a@"

      # Navigate back
      {state, _} = FormView.update({:move_focus, :previous}, state)
      assert state.focused_field_idx == 0

      # Edit name field
      {state, _} = FormView.update({:append_char, "name", "B"}, state)
      {state, _} = FormView.update({:append_char, "name", "o"}, state)
      {state, _} = FormView.update({:append_char, "name", "b"}, state)
      assert state.form_values["name"] == "Bob"

      # Complete email
      {state, _} = FormView.update({:move_focus, :next}, state)
      {state, _} = FormView.update({:backspace_field, "email"}, state)
      {state, _} = FormView.update({:backspace_field, "email"}, state)
      {state, _} = FormView.update({:append_char, "email", "b"}, state)
      {state, _} = FormView.update({:append_char, "email", "o"}, state)
      {state, _} = FormView.update({:append_char, "email", "b"}, state)
      {state, _} = FormView.update({:append_char, "email", "@"}, state)
      {state, _} = FormView.update({:append_char, "email", "e"}, state)
      assert state.form_values["email"] == "bob@e"

      # Submit form (now valid in our simple validator)
      {state, commands} = FormView.update(:submit_form, state)
      assert state.errors == %{}
      assert length(commands) == 1
    end

    test "edit flow: load values -> modify -> submit" do
      # Initialize edit form with pre-populated values - form values use string keys
      state = FormView.init(resource: "Post", mode: :edit, record_id: 10)
      assert state.form_values["title"] == "Post 10"
      assert state.has_changes == false

      # Navigate to body field
      {state, _} = FormView.update({:move_focus, :next}, state)
      assert state.focused_field_idx == 1

      # Edit body
      {state, _} = FormView.update({:append_char, "body", "!"}, state)
      assert state.has_changes == true

      # Submit form
      {_state, commands} = FormView.update(:submit_form, state)
      assert [{:parent_msg, {:submit_form, :edit, "Post", 10, _values}}] = commands
    end

    test "cancel flow: edit -> check changes -> cancel" do
      # Initialize form
      state = FormView.init(resource: "User", mode: :create)

      # Make a change
      {state, _} = FormView.update({:append_char, "name", "A"}, state)
      assert state.has_changes == true

      # Try to cancel - should trigger confirmation
      event = %Event.Key{key: :escape}
      {:msg, msg} = FormView.event_to_msg(event, state)
      assert msg == :confirm_cancel

      {_state, commands} = FormView.update(msg, state)
      assert commands == [{:parent_msg, {:cancel_form, "User"}}]
    end

    test "field navigation with wrapping" do
      state = FormView.init(resource: "User", mode: :create)

      # Start at first field
      assert state.focused_field_idx == 0

      # Press up to wrap to last
      {state, _} = FormView.update({:move_focus, :previous}, state)
      assert state.focused_field_idx == 2

      # Press down to wrap back to first
      {state, _} = FormView.update({:move_focus, :next}, state)
      assert state.focused_field_idx == 0
    end

    test "boolean toggle flow" do
      state = FormView.init(resource: "User", mode: :create)

      # Navigate to active field (boolean)
      {state, _} = FormView.update({:move_focus, :next}, state)
      {state, _} = FormView.update({:move_focus, :next}, state)
      assert state.focused_field_idx == 2

      # Toggle boolean - form values use string keys
      {state, _} = FormView.update({:toggle_boolean, "active"}, state)
      assert state.form_values["active"] == true

      # Toggle again
      {state, _} = FormView.update({:toggle_boolean, "active"}, state)
      assert state.form_values["active"] == false
    end
  end

  describe "resource types" do
    test "User resource has correct fields and validation" do
      state = FormView.init(resource: "User", mode: :create)

      assert state.fields == ["name", "email", "active"]

      # Test validation - errors use string keys
      {state, _} = FormView.update(:submit_form, state)
      assert Map.has_key?(state.errors, "name")
      assert Map.has_key?(state.errors, "email")
    end

    test "Post resource has correct fields and validation" do
      state = FormView.init(resource: "Post", mode: :create)

      assert state.fields == ["title", "body", "status", "is_featured"]

      # Test validation - errors use string keys
      {state, _} = FormView.update(:submit_form, state)
      assert Map.has_key?(state.errors, "title")
    end

    test "Unknown resource uses generic fields" do
      state = FormView.init(resource: "Unknown", mode: :create)

      assert state.fields == ["name", "description", "active"]

      # Generic validation allows submission
      {state, commands} = FormView.update(:submit_form, state)
      assert state.errors == %{}
      assert length(commands) == 1
    end
  end
end
