defmodule AshAdminTui.Components.ContentAreaTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Components.ContentArea

  alias AshAdminTui.Components.ContentArea
  alias TermUI.Widget.{VStack, Label}

  describe "init/1" do
    test "initializes with nil view_type (welcome screen)" do
      state = ContentArea.init([])

      assert state.view_type == nil
      assert state.view_states == %{list: %{}, detail: %{}, form: %{}, action: %{}}
      assert state.error_message == nil
      assert state.loading_message == nil
      assert state.previous_view == nil
    end
  end

  describe "view/1 - routing" do
    test "renders welcome screen when view_type is nil" do
      state = ContentArea.init([])

      {widget, _props, children} = ContentArea.view(state)

      assert widget == VStack
      assert is_list(children)
      assert length(children) > 0

      # Verify welcome message is present
      [{Label, label_props}] = children
      assert label_props.text =~ "Welcome to AshAdmin TUI"
      assert label_props.text =~ "Select a resource"
    end

    test "routes to list view when view_type is :list" do
      # Initialize proper ListView state
      list_state = AshAdminTui.Views.ListView.init(resource: "User")
      state = %{
        ContentArea.init([])
        | view_type: :list,
          view_states: %{list: list_state}
      }

      {widget, _props, _children} = ContentArea.view(state)

      # ListView returns a VStack
      assert widget == VStack
    end

    test "routes to detail view when view_type is :detail" do
      # Initialize proper DetailView state
      detail_state = AshAdminTui.Views.DetailView.init(resource: "User", record_id: 1)
      state = %{
        ContentArea.init([])
        | view_type: :detail,
          view_states: %{detail: detail_state}
      }

      {widget, _props, _children} = ContentArea.view(state)

      # DetailView returns a VStack
      assert widget == VStack
    end

    test "routes to form view when view_type is :form" do
      # Initialize proper FormView state
      form_state = AshAdminTui.Views.FormView.init(resource: "User", mode: :create)
      state = %{
        ContentArea.init([])
        | view_type: :form,
          view_states: %{form: form_state}
      }

      {widget, _props, _children} = ContentArea.view(state)

      # FormView returns a VStack
      assert widget == VStack
    end

    test "routes to action view when view_type is :action" do
      state = %{ContentArea.init([]) | view_type: :action}

      {widget, _props, children} = ContentArea.view(state)

      assert widget == VStack
      # Verify it renders action view content
      [{Label, label_props}] = children
      assert label_props.text =~ "Action View"
    end

    test "shows loading spinner when view_type is :loading" do
      state = %{ContentArea.init([]) | view_type: :loading, loading_message: "Loading data..."}

      {widget, _props, children} = ContentArea.view(state)

      assert widget == VStack
      [{Label, label_props}] = children
      assert label_props.text =~ "Loading data..."
      assert label_props.text =~ "Loading..."
    end

    test "shows loading spinner without message" do
      state = %{ContentArea.init([]) | view_type: :loading, loading_message: nil}

      {widget, _props, children} = ContentArea.view(state)

      assert widget == VStack
      [{Label, label_props}] = children
      assert label_props.text =~ "Loading..."
    end

    test "shows error message when view_type is :error" do
      state = %{ContentArea.init([]) | view_type: :error, error_message: "Failed to load data"}

      {widget, _props, children} = ContentArea.view(state)

      assert widget == VStack
      [{Label, label_props}] = children
      assert label_props.text =~ "Error"
      assert label_props.text =~ "Failed to load data"
      assert label_props.color == :red
    end

    test "shows generic error message when error_message is nil" do
      state = %{ContentArea.init([]) | view_type: :error, error_message: nil}

      {_widget, _props, children} = ContentArea.view(state)

      [{Label, label_props}] = children
      assert label_props.text =~ "An error occurred"
    end
  end

  describe "change_view/2 - view transitions" do
    test "sets view_type to :loading" do
      state = ContentArea.init([])
      params = %{resource: "User"}

      {new_state, _commands} = ContentArea.change_view(state, :list, params)

      assert new_state.view_type == :loading
    end

    test "stores previous view for potential return" do
      state = %{ContentArea.init([]) | view_type: :detail}
      params = %{resource: "User"}

      {new_state, _commands} = ContentArea.change_view(state, :list, params)

      assert new_state.previous_view == :detail
    end

    test "stores nil as previous view when no current view" do
      state = ContentArea.init([])
      params = %{resource: "User"}

      {new_state, _commands} = ContentArea.change_view(state, :list, params)

      assert new_state.previous_view == nil
    end

    test "returns fetch_view_data command for list view" do
      state = ContentArea.init([])
      params = %{resource: "User"}

      {_new_state, commands} = ContentArea.change_view(state, :list, params)

      assert commands == [{:fetch_view_data, :list, %{resource: "User"}}]
    end

    test "returns fetch_view_data command for detail view" do
      state = ContentArea.init([])
      params = %{resource: "User", id: 123}

      {_new_state, commands} = ContentArea.change_view(state, :detail, params)

      assert commands == [{:fetch_view_data, :detail, %{resource: "User", id: 123}}]
    end

    test "sets loading_message for list view" do
      state = ContentArea.init([])
      params = %{resource: "User"}

      {new_state, _commands} = ContentArea.change_view(state, :list, params)

      assert new_state.loading_message == "Loading User records..."
    end

    test "sets loading_message for detail view" do
      state = ContentArea.init([])
      params = %{resource: "User", id: 123}

      {new_state, _commands} = ContentArea.change_view(state, :detail, params)

      assert new_state.loading_message == "Loading User #123..."
    end

    test "sets loading_message for new form" do
      state = ContentArea.init([])
      params = %{resource: "User", mode: :new}

      {new_state, _commands} = ContentArea.change_view(state, :form, params)

      assert new_state.loading_message == "Preparing new User form..."
    end

    test "sets loading_message for edit form" do
      state = ContentArea.init([])
      params = %{resource: "User", mode: :edit, id: 123}

      {new_state, _commands} = ContentArea.change_view(state, :form, params)

      assert new_state.loading_message == "Loading User #123 for editing..."
    end

    test "sets loading_message for action view" do
      state = ContentArea.init([])
      params = %{resource: "User", action: "approve"}

      {new_state, _commands} = ContentArea.change_view(state, :action, params)

      assert new_state.loading_message == "Preparing approve action for User..."
    end
  end

  describe "complete_view_transition/3" do
    test "transitions from loading to target view" do
      state = %{ContentArea.init([]) | view_type: :loading}
      view_data = %{records: [], columns: []}

      {new_state, _commands} = ContentArea.complete_view_transition(state, :list, view_data)

      assert new_state.view_type == :list
    end

    test "stores view data in view_states" do
      state = ContentArea.init([])
      view_data = %{records: [%{id: 1}], columns: ["id", "name"]}

      {new_state, _commands} = ContentArea.complete_view_transition(state, :list, view_data)

      assert new_state.view_states.list == view_data
    end

    test "clears loading_message" do
      state = %{ContentArea.init([]) | view_type: :loading, loading_message: "Loading..."}
      view_data = %{}

      {new_state, _commands} = ContentArea.complete_view_transition(state, :list, view_data)

      assert new_state.loading_message == nil
    end

    test "returns empty commands list" do
      state = ContentArea.init([])
      view_data = %{}

      {_new_state, commands} = ContentArea.complete_view_transition(state, :list, view_data)

      assert commands == []
    end

    test "preserves other view states" do
      initial_detail_state = %{record: %{id: 1, name: "Test"}}
      state = %{ContentArea.init([]) |
        view_states: %{
          list: %{},
          detail: initial_detail_state,
          form: %{},
          action: %{}
        }
      }
      view_data = %{records: []}

      {new_state, _commands} = ContentArea.complete_view_transition(state, :list, view_data)

      assert new_state.view_states.detail == initial_detail_state
    end
  end

  describe "show_error/2" do
    test "sets view_type to :error" do
      state = ContentArea.init([])

      {new_state, _commands} = ContentArea.show_error(state, "Failed to load")

      assert new_state.view_type == :error
    end

    test "stores error message" do
      state = ContentArea.init([])

      {new_state, _commands} = ContentArea.show_error(state, "Failed to load")

      assert new_state.error_message == "Failed to load"
    end

    test "clears loading_message" do
      state = %{ContentArea.init([]) | loading_message: "Loading..."}

      {new_state, _commands} = ContentArea.show_error(state, "Failed to load")

      assert new_state.loading_message == nil
    end

    test "returns empty commands list" do
      state = ContentArea.init([])

      {_new_state, commands} = ContentArea.show_error(state, "Failed to load")

      assert commands == []
    end
  end

  describe "return_to_previous/1" do
    test "returns to previous view when one exists" do
      state = %{ContentArea.init([]) | view_type: :error, previous_view: :list}

      {new_state, _commands} = ContentArea.return_to_previous(state)

      assert new_state.view_type == :list
    end

    test "returns to welcome when no previous view" do
      state = %{ContentArea.init([]) | view_type: :error, previous_view: nil}

      {new_state, _commands} = ContentArea.return_to_previous(state)

      assert new_state.view_type == nil
    end

    test "clears error_message" do
      state = %{ContentArea.init([]) | error_message: "Some error", previous_view: :list}

      {new_state, _commands} = ContentArea.return_to_previous(state)

      assert new_state.error_message == nil
    end

    test "clears loading_message" do
      state = %{ContentArea.init([]) | loading_message: "Loading...", previous_view: :list}

      {new_state, _commands} = ContentArea.return_to_previous(state)

      assert new_state.loading_message == nil
    end

    test "clears previous_view" do
      state = %{ContentArea.init([]) | view_type: :error, previous_view: :list}

      {new_state, _commands} = ContentArea.return_to_previous(state)

      assert new_state.previous_view == nil
    end

    test "returns empty commands list" do
      state = %{ContentArea.init([]) | previous_view: :list}

      {_new_state, commands} = ContentArea.return_to_previous(state)

      assert commands == []
    end
  end

  describe "update/2" do
    test "handles {:change_view, view, params} message" do
      state = ContentArea.init([])

      {new_state, _commands} = ContentArea.update({:change_view, :list, %{resource: "User"}}, state)

      assert new_state.view_type == :loading
    end

    test "handles {:view_data_loaded, view, data} message" do
      state = %{ContentArea.init([]) | view_type: :loading}
      view_data = %{records: []}

      {new_state, _commands} = ContentArea.update({:view_data_loaded, :list, view_data}, state)

      assert new_state.view_type == :list
      assert new_state.view_states.list == view_data
    end

    test "handles {:view_load_error, message} message" do
      state = %{ContentArea.init([]) | view_type: :loading}

      {new_state, _commands} = ContentArea.update({:view_load_error, "Failed"}, state)

      assert new_state.view_type == :error
      assert new_state.error_message == "Failed"
    end

    test "handles :return_to_previous message" do
      state = %{ContentArea.init([]) | view_type: :error, previous_view: :list}

      {new_state, _commands} = ContentArea.update(:return_to_previous, state)

      assert new_state.view_type == :list
    end

    test "ignores unknown messages" do
      state = ContentArea.init([])

      {new_state, commands} = ContentArea.update(:unknown, state)

      assert new_state == state
      assert commands == []
    end
  end

  describe "integration - complete view transition flow" do
    test "full flow: init -> change_view -> load_data -> complete" do
      # 1. Initialize
      state = ContentArea.init([])
      assert state.view_type == nil

      # 2. Change to list view (starts loading)
      {state, commands} = ContentArea.change_view(state, :list, %{resource: "User"})
      assert state.view_type == :loading
      assert state.loading_message == "Loading User records..."
      assert state.previous_view == nil
      assert [{:fetch_view_data, :list, %{resource: "User"}}] = commands

      # 3. Data loaded successfully
      view_data = %{records: [%{id: 1}], columns: ["id", "name"]}
      {state, _commands} = ContentArea.complete_view_transition(state, :list, view_data)
      assert state.view_type == :list
      assert state.view_states.list == view_data
      assert state.loading_message == nil
    end

    test "full flow: init -> change_view -> error" do
      # 1. Initialize
      state = ContentArea.init([])

      # 2. Change to list view (starts loading)
      {state, _commands} = ContentArea.change_view(state, :list, %{resource: "User"})
      assert state.view_type == :loading

      # 3. Error occurs
      {state, _commands} = ContentArea.show_error(state, "Connection failed")
      assert state.view_type == :error
      assert state.error_message == "Connection failed"
      assert state.loading_message == nil
    end

    test "preserves view state when switching between views" do
      state = ContentArea.init([])

      # Load list view
      list_data = %{records: [%{id: 1}]}
      {state, _} = ContentArea.complete_view_transition(state, :list, list_data)

      # Switch to detail view
      {state, _} = ContentArea.change_view(state, :detail, %{resource: "User", id: 1})
      detail_data = %{record: %{id: 1, name: "Test"}}
      {state, _} = ContentArea.complete_view_transition(state, :detail, detail_data)

      # List view state should still be preserved
      assert state.view_states.list == list_data
      assert state.view_states.detail == detail_data
    end

    test "can return to previous view from error" do
      state = ContentArea.init([])

      # Start in list view
      {state, _} = ContentArea.complete_view_transition(state, :list, %{})

      # Try to change view, but encounter error
      {state, _} = ContentArea.change_view(state, :detail, %{resource: "User", id: 1})
      # previous_view is now :list (set by change_view)
      assert state.previous_view == :list

      {state, _} = ContentArea.show_error(state, "Not found")
      # previous_view is still :list (preserved by show_error)

      # Return to previous view
      {state, _} = ContentArea.return_to_previous(state)
      assert state.view_type == :list  # Returns to the view we were in before the transition
    end
  end

  describe "view state isolation" do
    test "each view type maintains separate state" do
      state = ContentArea.init([])

      # Set data for list view
      list_data = %{records: [%{id: 1}, %{id: 2}]}
      {state, _} = ContentArea.complete_view_transition(state, :list, list_data)

      # Set data for detail view
      detail_data = %{record: %{id: 1, name: "John"}}
      {state, _} = ContentArea.complete_view_transition(state, :detail, detail_data)

      # Set data for form view
      form_data = %{fields: ["name", "email"]}
      {state, _} = ContentArea.complete_view_transition(state, :form, form_data)

      # All states should be preserved independently
      assert state.view_states.list == list_data
      assert state.view_states.detail == detail_data
      assert state.view_states.form == form_data
      assert state.view_states.action == %{}
    end

    test "updating one view does not affect others" do
      state = ContentArea.init([])

      # Set initial data for list view
      list_data_v1 = %{records: [%{id: 1}]}
      {state, _} = ContentArea.complete_view_transition(state, :list, list_data_v1)

      # Set data for detail view
      detail_data = %{record: %{id: 1}}
      {state, _} = ContentArea.complete_view_transition(state, :detail, detail_data)

      # Update list view with new data
      list_data_v2 = %{records: [%{id: 1}, %{id: 2}]}
      {state, _} = ContentArea.complete_view_transition(state, :list, list_data_v2)

      # Detail view should be unchanged
      assert state.view_states.detail == detail_data
      assert state.view_states.list == list_data_v2
    end
  end
end
