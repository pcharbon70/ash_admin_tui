defmodule AshAdminTui.Views.ListViewTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Views.ListView

  alias AshAdminTui.Views.ListView
  alias TermUI.Event
  alias TermUI.Widget.{VStack, HStack, Label}

  describe "init/1" do
    test "initializes with mock data" do
      state = ListView.init(resource: "User")

      assert state.resource.name == "User"
      assert length(state.records) == 10
      assert state.selected_row == 0
      assert is_list(state.columns)
      assert state.page == 1
      assert state.page_size == 10
    end

    test "initializes with correct columns for User resource" do
      state = ListView.init(resource: "User")

      assert state.columns == ["id", "name", "email", "active"]
      assert state.resource.columns == ["id", "name", "email", "active"]
    end

    test "initializes with correct columns for Post resource" do
      state = ListView.init(resource: "Post")

      assert state.columns == ["id", "title", "status", "views"]
    end

    test "initializes with default columns for unknown resource" do
      state = ListView.init(resource: "Unknown")

      assert state.columns == ["id", "name", "created_at"]
    end

    test "records have correct structure for User resource" do
      state = ListView.init(resource: "User")

      first_record = List.first(state.records)
      # Records use string keys to avoid atom table exhaustion
      assert Map.has_key?(first_record, "id")
      assert Map.has_key?(first_record, "name")
      assert Map.has_key?(first_record, "email")
      assert Map.has_key?(first_record, "active")
    end

    test "initializes with sort state" do
      state = ListView.init(resource: "User")

      assert is_map(state.sort)
      assert state.sort.direction == :asc
    end
  end

  describe "view/1 - structure" do
    test "renders VStack with header, rows, and footer" do
      state = ListView.init(resource: "User")

      {widget, _props, children} = ListView.view(state)

      assert widget == VStack
      assert length(children) == 3  # header, rows, footer
    end

    test "header contains column names" do
      state = ListView.init(resource: "User")

      {VStack, _props, [header | _rest]} = ListView.view(state)
      {HStack, _hprops, labels} = header

      # Should have labels for each column
      assert length(labels) == length(state.columns)

      # First label should be "Id" (capitalized)
      [{Label, first_label_props} | _] = labels
      assert first_label_props.text =~ "Id"
      assert first_label_props.style == :bold
    end

    test "rows section contains all records" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, rows, _footer]} = ListView.view(state)
      {VStack, _row_props, row_list} = rows

      # Should have one row for each record
      assert length(row_list) == length(state.records)
    end

    test "each row contains cells for all columns" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, rows, _footer]} = ListView.view(state)
      {VStack, _row_props, [first_row | _rest]} = rows
      {HStack, _row_hprops, cells} = first_row

      # Should have one cell for each column
      assert length(cells) == length(state.columns)
    end

    test "selected row has reverse style" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, rows, _footer]} = ListView.view(state)
      {VStack, _row_props, [first_row | _rest]} = rows
      {HStack, _row_hprops, cells} = first_row

      # First row is selected (index 0), so all cells should have reverse style
      Enum.each(cells, fn {Label, props} ->
        assert props.style == :reverse
      end)
    end

    test "unselected rows have normal style" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, rows, _footer]} = ListView.view(state)
      {VStack, _row_props, [_first_row, second_row | _rest]} = rows
      {HStack, _row_hprops, cells} = second_row

      # Second row is not selected, so cells should have normal style
      Enum.each(cells, fn {Label, props} ->
        assert props.style == :normal
      end)
    end

    test "footer contains pagination info" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, _rows, footer]} = ListView.view(state)
      {Label, footer_props} = footer

      assert footer_props.text =~ "Page"
      assert footer_props.text =~ "Records"
      assert footer_props.style == :dim
    end

    test "footer contains action shortcuts" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, _rows, footer]} = ListView.view(state)
      {Label, footer_props} = footer

      assert footer_props.text =~ "[N]ew"
      assert footer_props.text =~ "[E]dit"
      assert footer_props.text =~ "[D]elete"
      assert footer_props.text =~ "[A]ctions"
    end
  end

  describe "event_to_msg/2 - navigation" do
    test "Down arrow generates move_selection :down message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :arrow_down}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "Up arrow generates move_selection :up message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :arrow_up}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end

    test "Page Down generates move_selection :page_down message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :page_down}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :page_down}}
    end

    test "Page Up generates move_selection :page_up message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :page_up}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :page_up}}
    end

    test "Home generates move_selection :home message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :home}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :home}}
    end

    test "End generates move_selection :end message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :end}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :end}}
    end

    test "j key generates move_selection :down message (vim-style)" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "j"}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "k key generates move_selection :up message (vim-style)" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "k"}

      assert ListView.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end
  end

  describe "event_to_msg/2 - actions" do
    test "Enter generates view_detail message with record id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :enter}

      assert ListView.event_to_msg(event, state) == {:msg, {:view_detail, 1}}
    end

    test "n key generates new_record message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "n"}

      assert ListView.event_to_msg(event, state) == {:msg, :new_record}
    end

    test "N key generates new_record message" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "N"}

      assert ListView.event_to_msg(event, state) == {:msg, :new_record}
    end

    test "e key generates edit_record message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "e"}

      assert ListView.event_to_msg(event, state) == {:msg, {:edit_record, 1}}
    end

    test "E key generates edit_record message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "E"}

      assert ListView.event_to_msg(event, state) == {:msg, {:edit_record, 1}}
    end

    test "d key generates delete_record message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "d"}

      assert ListView.event_to_msg(event, state) == {:msg, {:delete_record, 1}}
    end

    test "D key generates delete_record message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "D"}

      assert ListView.event_to_msg(event, state) == {:msg, {:delete_record, 1}}
    end

    test "a key generates show_actions message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "a"}

      assert ListView.event_to_msg(event, state) == {:msg, {:show_actions, 1}}
    end

    test "A key generates show_actions message with selected id" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "A"}

      assert ListView.event_to_msg(event, state) == {:msg, {:show_actions, 1}}
    end

    test "actions use selected row id" do
      state = %{ListView.init(resource: "User") | selected_row: 2}

      # Edit action should use id from third record (index 2)
      event = %Event.Key{key: :char, char: "e"}
      assert ListView.event_to_msg(event, state) == {:msg, {:edit_record, 3}}
    end

    test "ignores unknown keys" do
      state = ListView.init(resource: "User")
      event = %Event.Key{key: :char, char: "x"}

      assert ListView.event_to_msg(event, state) == :ignore
    end
  end

  describe "update/2 - navigation" do
    test "move_selection :down increments selected_row" do
      state = ListView.init(resource: "User")
      initial_row = state.selected_row

      {new_state, _commands} = ListView.update({:move_selection, :down}, state)

      assert new_state.selected_row == initial_row + 1
    end

    test "move_selection :up decrements selected_row" do
      state = %{ListView.init(resource: "User") | selected_row: 5}

      {new_state, _commands} = ListView.update({:move_selection, :up}, state)

      assert new_state.selected_row == 4
    end

    test "move_selection :down wraps at end" do
      state = ListView.init(resource: "User")
      max_index = length(state.records) - 1
      state = %{state | selected_row: max_index}

      {new_state, _commands} = ListView.update({:move_selection, :down}, state)

      assert new_state.selected_row == 0
    end

    test "move_selection :up wraps at start" do
      state = %{ListView.init(resource: "User") | selected_row: 0}
      max_index = length(state.records) - 1

      {new_state, _commands} = ListView.update({:move_selection, :up}, state)

      assert new_state.selected_row == max_index
    end

    test "move_selection :page_down advances by page_size" do
      state = %{ListView.init(resource: "User") | selected_row: 0, page_size: 10}

      {new_state, _commands} = ListView.update({:move_selection, :page_down}, state)

      # Since we only have 10 records (0-9), advancing by 10 should hit max
      assert new_state.selected_row == 9
    end

    test "move_selection :page_up goes back by page_size" do
      state = %{ListView.init(resource: "User") | selected_row: 9, page_size: 10}

      {new_state, _commands} = ListView.update({:move_selection, :page_up}, state)

      # Going back by 10 from 9 should land at 0 (clamped)
      assert new_state.selected_row == 0
    end

    test "move_selection :home jumps to first row" do
      state = %{ListView.init(resource: "User") | selected_row: 5}

      {new_state, _commands} = ListView.update({:move_selection, :home}, state)

      assert new_state.selected_row == 0
    end

    test "move_selection :end jumps to last row" do
      state = ListView.init(resource: "User")
      max_index = length(state.records) - 1

      {new_state, _commands} = ListView.update({:move_selection, :end}, state)

      assert new_state.selected_row == max_index
    end
  end

  describe "update/2 - actions" do
    test "view_detail returns parent_msg command" do
      state = ListView.init(resource: "User")

      {_new_state, commands} = ListView.update({:view_detail, 1}, state)

      assert commands == [{:parent_msg, {:view_detail, "User", 1}}]
    end

    test "new_record returns parent_msg command" do
      state = ListView.init(resource: "User")

      {_new_state, commands} = ListView.update(:new_record, state)

      assert commands == [{:parent_msg, {:new_record, "User"}}]
    end

    test "edit_record returns parent_msg command" do
      state = ListView.init(resource: "User")

      {_new_state, commands} = ListView.update({:edit_record, 5}, state)

      assert commands == [{:parent_msg, {:edit_record, "User", 5}}]
    end

    test "delete_record returns parent_msg command" do
      state = ListView.init(resource: "User")

      {_new_state, commands} = ListView.update({:delete_record, 3}, state)

      assert commands == [{:parent_msg, {:delete_record, "User", 3}}]
    end

    test "show_actions returns parent_msg command" do
      state = ListView.init(resource: "User")

      {_new_state, commands} = ListView.update({:show_actions, 2}, state)

      assert commands == [{:parent_msg, {:show_actions, "User", 2}}]
    end

    test "unknown messages return unchanged state" do
      state = ListView.init(resource: "User")

      {new_state, commands} = ListView.update(:unknown, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "integration - complete flows" do
    test "navigation flow: down -> down -> up" do
      state = ListView.init(resource: "User")
      assert state.selected_row == 0

      # Move down
      {state, _} = ListView.update({:move_selection, :down}, state)
      assert state.selected_row == 1

      # Move down again
      {state, _} = ListView.update({:move_selection, :down}, state)
      assert state.selected_row == 2

      # Move up
      {state, _} = ListView.update({:move_selection, :up}, state)
      assert state.selected_row == 1
    end

    test "action flow: navigate -> select action" do
      state = ListView.init(resource: "User")

      # Navigate to row 3
      {state, _} = ListView.update({:move_selection, :down}, state)
      {state, _} = ListView.update({:move_selection, :down}, state)
      {state, _} = ListView.update({:move_selection, :down}, state)
      assert state.selected_row == 3

      # View detail of selected record (id: 4)
      {_state, commands} = ListView.update({:view_detail, 4}, state)
      assert commands == [{:parent_msg, {:view_detail, "User", 4}}]
    end

    test "page navigation: home -> end -> page_up" do
      state = ListView.init(resource: "User")

      # Start in middle
      state = %{state | selected_row: 5}

      # Jump to first
      {state, _} = ListView.update({:move_selection, :home}, state)
      assert state.selected_row == 0

      # Jump to last
      {state, _} = ListView.update({:move_selection, :end}, state)
      assert state.selected_row == 9

      # Page up
      {state, _} = ListView.update({:move_selection, :page_up}, state)
      assert state.selected_row == 0  # 9 - 10 clamped to 0
    end

    test "wrapping: down past end wraps to start" do
      state = ListView.init(resource: "User")
      state = %{state | selected_row: 9}  # Last record

      {state, _} = ListView.update({:move_selection, :down}, state)
      assert state.selected_row == 0
    end

    test "wrapping: up past start wraps to end" do
      state = ListView.init(resource: "User")
      state = %{state | selected_row: 0}  # First record

      {state, _} = ListView.update({:move_selection, :up}, state)
      assert state.selected_row == 9  # Last record
    end
  end

  describe "pagination info" do
    test "footer shows correct page and record range" do
      state = ListView.init(resource: "User")

      {VStack, _props, [_header, _rows, footer]} = ListView.view(state)
      {Label, footer_props} = footer

      # Should show page 1, records 1-10 of 42
      assert footer_props.text =~ "Page 1"
      assert footer_props.text =~ "Records 1-10"
      assert footer_props.text =~ "of 42"
    end

    test "footer calculates correct range for page 2" do
      state = %{ListView.init(resource: "User") | page: 2}

      {VStack, _props, [_header, _rows, footer]} = ListView.view(state)
      {Label, footer_props} = footer

      # Should show page 2, records 11-20 of 42
      assert footer_props.text =~ "Page 2"
      assert footer_props.text =~ "Records 11-20"
    end

    test "footer shows total pages" do
      state = ListView.init(resource: "User")
      # 42 total records, 10 per page = 5 pages

      {VStack, _props, [_header, _rows, footer]} = ListView.view(state)
      {Label, footer_props} = footer

      assert footer_props.text =~ "of 5"  # 5 total pages
    end
  end

  describe "different resource types" do
    test "Post resource has correct columns and data" do
      state = ListView.init(resource: "Post")

      assert state.columns == ["id", "title", "status", "views"]
      first_record = List.first(state.records)
      # Records use string keys to avoid atom table exhaustion
      assert Map.has_key?(first_record, "title")
      assert Map.has_key?(first_record, "status")
      assert Map.has_key?(first_record, "views")
    end

    test "unknown resource has generic columns" do
      state = ListView.init(resource: "CustomResource")

      assert state.columns == ["id", "name", "created_at"]
      first_record = List.first(state.records)
      # Records use string keys to avoid atom table exhaustion
      assert Map.has_key?(first_record, "id")
      assert Map.has_key?(first_record, "name")
      assert Map.has_key?(first_record, "created_at")
    end
  end
end
