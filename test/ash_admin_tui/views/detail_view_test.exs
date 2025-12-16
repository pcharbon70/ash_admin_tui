defmodule AshAdminTui.Views.DetailViewTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Views.DetailView

  alias AshAdminTui.Views.DetailView
  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack, HStack}

  describe "init/1" do
    test "initializes with mock data for User resource" do
      state = DetailView.init(resource: "User", record_id: 1)

      assert state.resource.name == "User"
      assert state.record.id == 1
      assert state.record.name == "User 1"
      assert state.record.email == "user1@example.com"
      assert state.selected_field_idx == 0
    end

    test "initializes with mock data for Post resource" do
      state = DetailView.init(resource: "Post", record_id: 2)

      assert state.resource.name == "Post"
      assert state.record.id == 2
      assert state.record.title == "Post 2"
      assert is_binary(state.record.body)
      assert state.selected_field_idx == 0
    end

    test "initializes with correct fields for User resource" do
      state = DetailView.init(resource: "User", record_id: 1)

      assert state.fields == ["id", "name", "email", "active", "created_at", "last_login", "post_count"]
    end

    test "initializes with correct fields for Post resource" do
      state = DetailView.init(resource: "Post", record_id: 1)

      assert state.fields == ["id", "title", "body", "status", "views", "published_at", "is_featured"]
    end

    test "loads relationships for User resource" do
      state = DetailView.init(resource: "User", record_id: 1)

      assert Map.has_key?(state.relationships, :posts)
      assert length(state.relationships.posts) == 3
    end

    test "loads relationships for Post resource" do
      state = DetailView.init(resource: "Post", record_id: 10)

      assert Map.has_key?(state.relationships, :author)
      assert Map.has_key?(state.relationships, :comments)
      assert length(state.relationships.author) == 1
      assert length(state.relationships.comments) == 2
    end

    test "initializes with generic mock data for unknown resource" do
      state = DetailView.init(resource: "Unknown", record_id: 5)

      assert state.resource.name == "Unknown"
      assert state.record.id == 5
      assert state.record.name == "Record 5"
    end
  end

  describe "view/1 - structure" do
    test "renders VStack with title, attributes, relationships, and footer" do
      state = DetailView.init(resource: "User", record_id: 1)

      {widget, _props, children} = DetailView.view(state)

      assert widget == VStack
      assert length(children) == 4  # title, attributes, relationships, footer
    end

    test "renders title with resource name and ID" do
      state = DetailView.init(resource: "User", record_id: 42)

      {VStack, _props, [title | _rest]} = DetailView.view(state)
      {Label, props} = title

      assert props.text == "User #42"
      assert props.style == :bold
    end

    test "renders attributes section with all fields" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, [_title, attributes | _rest]} = DetailView.view(state)
      {VStack, _attr_props, [header, {VStack, _rows_props, rows}]} = attributes

      {Label, header_props} = header
      assert header_props.text == "Attributes:"
      assert header_props.style == :bold

      # Should have one row per field
      assert length(rows) == length(state.fields)
    end

    test "renders relationships section" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, [_title, _attributes, relationships | _rest]} = DetailView.view(state)
      {VStack, _rel_props, [_blank, header | _rows]} = relationships

      {Label, header_props} = header
      assert header_props.text == "Relationships:"
      assert header_props.style == :bold
    end

    test "renders footer with action shortcuts" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, children} = DetailView.view(state)
      footer = List.last(children)
      {Label, footer_props} = footer

      assert footer_props.style == :dim
      assert String.contains?(footer_props.text, "[E]dit")
      assert String.contains?(footer_props.text, "[D]elete")
      assert String.contains?(footer_props.text, "[B]ack")
      assert String.contains?(footer_props.text, "[A]ctions")
    end
  end

  describe "view/1 - field layout" do
    test "fields use two-column layout" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, [_title, attributes | _rest]} = DetailView.view(state)
      {VStack, _attr_props, [_header, {VStack, _rows_props, rows}]} = attributes

      # Check first row has HStack with two labels
      first_row = hd(rows)
      {HStack, _row_props, cells} = first_row

      assert length(cells) == 2  # field name and value

      # Check field name label
      {Label, name_props} = Enum.at(cells, 0)
      assert String.contains?(name_props.text, ":")

      # Check value label
      {Label, _value_props} = Enum.at(cells, 1)
    end

    test "selected field has reverse style" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}

      {VStack, _props, [_title, attributes | _rest]} = DetailView.view(state)
      {VStack, _attr_props, [_header, {VStack, _rows_props, rows}]} = attributes

      first_row = hd(rows)
      {HStack, _row_props, cells} = first_row

      Enum.each(cells, fn {Label, props} ->
        assert props.style == :reverse
      end)
    end

    test "unselected field has normal style" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}

      {VStack, _props, [_title, attributes | _rest]} = DetailView.view(state)
      {VStack, _attr_props, [_header, {VStack, _rows_props, rows}]} = attributes

      second_row = Enum.at(rows, 1)
      {HStack, _row_props, cells} = second_row

      Enum.each(cells, fn {Label, props} ->
        assert props.style == :normal
      end)
    end
  end

  describe "format_field/2" do
    test "formats strings as-is" do
      assert DetailView.format_field(:name, "Alice") == "Alice"
      assert DetailView.format_field(:email, "alice@example.com") == "alice@example.com"
    end

    test "formats integers with thousand separators" do
      assert DetailView.format_field(:count, 1000) == "1,000"
      assert DetailView.format_field(:count, 1234567) == "1,234,567"
      assert DetailView.format_field(:count, 42) == "42"
    end

    test "formats floats" do
      result = DetailView.format_field(:price, 19.99)
      assert is_binary(result)
      assert String.contains?(result, "19.99")
    end

    test "formats booleans as Yes/No" do
      assert DetailView.format_field(:active, true) == "Yes"
      assert DetailView.format_field(:active, false) == "No"
    end

    test "formats dates in YYYY-MM-DD format" do
      date = ~D[2024-01-15]
      result = DetailView.format_field(:created_at, date)
      assert result == "2024-01-15"
    end

    test "formats datetimes" do
      datetime = ~U[2024-12-01 10:30:00Z]
      result = DetailView.format_field(:updated_at, datetime)
      assert is_binary(result)
      assert String.contains?(result, "2024")
    end

    test "formats nil as empty string" do
      assert DetailView.format_field(:optional, nil) == ""
    end

    test "formats unknown types with inspect" do
      result = DetailView.format_field(:custom, {:tuple, "value"})
      assert is_binary(result)
    end
  end

  describe "view/1 - relationships" do
    test "displays relationships with arrow indicator" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, [_title, _attributes, relationships | _rest]} = DetailView.view(state)
      {VStack, _rel_props, [_blank, _header, {VStack, _rows_props, rows}]} = relationships

      posts_row = hd(rows)
      {HStack, _row_props, [_name_label, value_label]} = posts_row
      {Label, value_props} = value_label

      assert String.starts_with?(value_props.text, "→")
    end

    test "displays relationship count when multiple records" do
      state = DetailView.init(resource: "User", record_id: 1)

      {VStack, _props, [_title, _attributes, relationships | _rest]} = DetailView.view(state)
      {VStack, _rel_props, [_blank, _header, {VStack, _rows_props, rows}]} = relationships

      posts_row = hd(rows)
      {HStack, _row_props, [_name_label, value_label]} = posts_row
      {Label, value_props} = value_label

      # User has 3 posts, so should show "+2 more"
      assert String.contains?(value_props.text, "+2 more")
    end

    test "displays (none) for empty relationships" do
      # Create a state with no relationships
      state = DetailView.init(resource: "Unknown", record_id: 1)

      {VStack, _props, children} = DetailView.view(state)
      relationships = Enum.at(children, 2)

      # Unknown resource has no relationships, so section should be empty label
      {Label, props} = relationships
      assert props.text == ""
    end

    test "selected relationship has reverse style" do
      state = DetailView.init(resource: "User", record_id: 1)
      # Select first relationship (after all fields)
      total_fields = length(state.fields)
      state = %{state | selected_field_idx: total_fields}

      {VStack, _props, [_title, _attributes, relationships | _rest]} = DetailView.view(state)
      {VStack, _rel_props, [_blank, _header, {VStack, _rows_props, rows}]} = relationships

      first_relationship_row = hd(rows)
      {HStack, _row_props, cells} = first_relationship_row

      Enum.each(cells, fn {Label, props} ->
        assert props.style == :reverse
      end)
    end
  end

  describe "event_to_msg/2 - navigation" do
    test "Down arrow generates move_selection down message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :arrow_down}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "Up arrow generates move_selection up message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :arrow_up}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end

    test "Home key generates move_selection home message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :home}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :home}}
    end

    test "End key generates move_selection end message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :end}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :end}}
    end

    test "j key generates move_selection down message (vim-style)" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :char, char: "j"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "k key generates move_selection up message (vim-style)" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :char, char: "k"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end

    test "unknown keys are ignored" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :char, char: "x"}

      assert DetailView.event_to_msg(event, state) == :ignore
    end
  end

  describe "event_to_msg/2 - actions" do
    test "e key generates edit_record message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "e"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:edit_record, 42}}
    end

    test "E key generates edit_record message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "E"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:edit_record, 42}}
    end

    test "d key generates delete_record message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "d"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:delete_record, 42}}
    end

    test "D key generates delete_record message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "D"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:delete_record, 42}}
    end

    test "b key generates back_to_list message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :char, char: "b"}

      assert DetailView.event_to_msg(event, state) == {:msg, :back_to_list}
    end

    test "B key generates back_to_list message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :char, char: "B"}

      assert DetailView.event_to_msg(event, state) == {:msg, :back_to_list}
    end

    test "Escape key generates back_to_list message" do
      state = DetailView.init(resource: "User", record_id: 1)
      event = %Event.Key{key: :escape}

      assert DetailView.event_to_msg(event, state) == {:msg, :back_to_list}
    end

    test "a key generates show_actions message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "a"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:show_actions, 42}}
    end

    test "A key generates show_actions message" do
      state = DetailView.init(resource: "User", record_id: 42)
      event = %Event.Key{key: :char, char: "A"}

      assert DetailView.event_to_msg(event, state) == {:msg, {:show_actions, 42}}
    end

    test "Enter on relationship generates navigate_to_related message" do
      state = DetailView.init(resource: "User", record_id: 1)
      # Select first relationship (after all fields)
      total_fields = length(state.fields)
      state = %{state | selected_field_idx: total_fields}

      event = %Event.Key{key: :enter}

      {:msg, {:navigate_to_related, relationship_name, record_id}} = DetailView.event_to_msg(event, state)

      assert relationship_name == :posts
      assert record_id == 10  # First post ID for user 1
    end

    test "Enter on attribute field is ignored" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}  # On first attribute

      event = %Event.Key{key: :enter}

      assert DetailView.event_to_msg(event, state) == :ignore
    end
  end

  describe "update/2 - navigation" do
    test "move_selection down increments selected_field_idx" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}

      {new_state, _commands} = DetailView.update({:move_selection, :down}, state)

      assert new_state.selected_field_idx == 1
    end

    test "move_selection up decrements selected_field_idx" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 2}

      {new_state, _commands} = DetailView.update({:move_selection, :up}, state)

      assert new_state.selected_field_idx == 1
    end

    test "move_selection down wraps at end" do
      state = DetailView.init(resource: "User", record_id: 1)
      total_items = length(state.fields) + map_size(state.relationships)
      state = %{state | selected_field_idx: total_items - 1}

      {new_state, _commands} = DetailView.update({:move_selection, :down}, state)

      assert new_state.selected_field_idx == 0
    end

    test "move_selection up wraps at start" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}

      {new_state, _commands} = DetailView.update({:move_selection, :up}, state)

      total_items = length(state.fields) + map_size(state.relationships)
      assert new_state.selected_field_idx == total_items - 1
    end

    test "move_selection home jumps to first field" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 5}

      {new_state, _commands} = DetailView.update({:move_selection, :home}, state)

      assert new_state.selected_field_idx == 0
    end

    test "move_selection end jumps to last item" do
      state = DetailView.init(resource: "User", record_id: 1)
      state = %{state | selected_field_idx: 0}

      {new_state, _commands} = DetailView.update({:move_selection, :end}, state)

      total_items = length(state.fields) + map_size(state.relationships)
      assert new_state.selected_field_idx == total_items - 1
    end
  end

  describe "update/2 - actions" do
    test "edit_record generates parent message command" do
      state = DetailView.init(resource: "User", record_id: 42)

      {new_state, commands} = DetailView.update({:edit_record, 42}, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:edit_record, "User", 42}}]
    end

    test "delete_record generates parent message command" do
      state = DetailView.init(resource: "User", record_id: 42)

      {new_state, commands} = DetailView.update({:delete_record, 42}, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:delete_record, "User", 42}}]
    end

    test "back_to_list generates parent message command" do
      state = DetailView.init(resource: "User", record_id: 1)

      {new_state, commands} = DetailView.update(:back_to_list, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:back_to_list, "User"}}]
    end

    test "show_actions generates parent message command" do
      state = DetailView.init(resource: "Post", record_id: 10)

      {new_state, commands} = DetailView.update({:show_actions, 10}, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:show_actions, "Post", 10}}]
    end

    test "navigate_to_related generates parent message command" do
      state = DetailView.init(resource: "User", record_id: 1)

      {new_state, commands} = DetailView.update({:navigate_to_related, :posts, 10}, state)

      assert new_state == state
      assert commands == [{:parent_msg, {:navigate_to_related, :posts, 10}}]
    end

    test "unknown message returns unchanged state" do
      state = DetailView.init(resource: "User", record_id: 1)

      {new_state, commands} = DetailView.update(:unknown_message, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "integration - complete flows" do
    test "navigation flow: down -> down -> up" do
      state = DetailView.init(resource: "User", record_id: 1)
      assert state.selected_field_idx == 0

      {state, _} = DetailView.update({:move_selection, :down}, state)
      assert state.selected_field_idx == 1

      {state, _} = DetailView.update({:move_selection, :down}, state)
      assert state.selected_field_idx == 2

      {state, _} = DetailView.update({:move_selection, :up}, state)
      assert state.selected_field_idx == 1
    end

    test "action flow: view detail -> edit -> back" do
      # Initialize detail view
      state = DetailView.init(resource: "User", record_id: 5)
      assert state.record.id == 5

      # Press 'e' to edit
      event = %Event.Key{key: :char, char: "e"}
      {:msg, msg} = DetailView.event_to_msg(event, state)
      assert msg == {:edit_record, 5}

      {_state, commands} = DetailView.update(msg, state)
      assert commands == [{:parent_msg, {:edit_record, "User", 5}}]

      # Press 'b' to go back
      event = %Event.Key{key: :char, char: "b"}
      {:msg, msg} = DetailView.event_to_msg(event, state)
      assert msg == :back_to_list

      {_state, commands} = DetailView.update(msg, state)
      assert commands == [{:parent_msg, {:back_to_list, "User"}}]
    end

    test "relationship navigation flow" do
      # Initialize User detail view
      state = DetailView.init(resource: "User", record_id: 1)

      # Navigate to relationships section
      total_fields = length(state.fields)
      {state, _} = DetailView.update({:move_selection, :end}, state)
      assert state.selected_field_idx >= total_fields

      # Press Enter to navigate to related record
      event = %Event.Key{key: :enter}
      {:msg, msg} = DetailView.event_to_msg(event, state)
      assert {:navigate_to_related, :posts, _id} = msg

      {_state, commands} = DetailView.update(msg, state)
      assert [{:parent_msg, {:navigate_to_related, :posts, _id}}] = commands
    end

    test "field navigation with wrapping" do
      state = DetailView.init(resource: "User", record_id: 1)

      # Start at first field
      assert state.selected_field_idx == 0

      # Press up to wrap to last
      {state, _} = DetailView.update({:move_selection, :up}, state)
      total_items = length(state.fields) + map_size(state.relationships)
      assert state.selected_field_idx == total_items - 1

      # Press down to wrap back to first
      {state, _} = DetailView.update({:move_selection, :down}, state)
      assert state.selected_field_idx == 0
    end

    test "home and end navigation" do
      state = DetailView.init(resource: "User", record_id: 1)

      # Jump to end
      {state, _} = DetailView.update({:move_selection, :end}, state)
      total_items = length(state.fields) + map_size(state.relationships)
      assert state.selected_field_idx == total_items - 1

      # Jump to home
      {state, _} = DetailView.update({:move_selection, :home}, state)
      assert state.selected_field_idx == 0
    end
  end

  describe "resource types" do
    test "User resource has correct fields and relationships" do
      state = DetailView.init(resource: "User", record_id: 1)

      assert "name" in state.fields
      assert "email" in state.fields
      assert "active" in state.fields
      assert Map.has_key?(state.relationships, :posts)
    end

    test "Post resource has correct fields and relationships" do
      state = DetailView.init(resource: "Post", record_id: 1)

      assert "title" in state.fields
      assert "body" in state.fields
      assert "status" in state.fields
      assert Map.has_key?(state.relationships, :author)
      assert Map.has_key?(state.relationships, :comments)
    end

    test "Unknown resource uses generic fields" do
      state = DetailView.init(resource: "Unknown", record_id: 1)

      assert state.fields == ["id", "name", "description", "created_at", "updated_at"]
      assert state.relationships == %{}
    end
  end
end
