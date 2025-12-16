defmodule AshAdminTui.Components.SidebarTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Components.Sidebar

  alias AshAdminTui.Components.Sidebar
  alias TermUI.Event
  alias TermUI.Widget.{VStack, Label}

  describe "init/1" do
    test "initializes with mock domains and resources" do
      state = Sidebar.init([])

      assert is_list(state.domains)
      assert length(state.domains) > 0
      assert state.selected_index == 0
      assert MapSet.member?(state.expanded_domains, "Accounts")
    end

    test "domains have names and resources" do
      state = Sidebar.init([])

      Enum.each(state.domains, fn domain ->
        assert is_binary(domain.name)
        assert is_list(domain.resources)
      end)
    end
  end

  describe "view/1 - tree rendering" do
    test "renders tree structure in VStack" do
      state = Sidebar.init([])

      {widget, _props, children} = Sidebar.view(state)

      assert widget == VStack
      assert is_list(children)
      assert length(children) > 0
    end

    test "expanded domains show ▼ indicator" do
      state = Sidebar.init([])
      # Accounts is expanded by default

      {_widget, _props, children} = Sidebar.view(state)
      [first_label | _rest] = children
      {Label, %{text: text}} = first_label

      assert text =~ "▼"
      assert text =~ "Accounts"
    end

    test "collapsed domains show ▶ indicator" do
      state = Sidebar.init([])
      # Blog is collapsed by default

      {_widget, _props, children} = Sidebar.view(state)
      # Find Blog domain in the list
      blog_label =
        Enum.find(children, fn
          {Label, %{text: text}} -> text =~ "Blog"
          _ -> false
        end)

      assert blog_label != nil
      {Label, %{text: text}} = blog_label
      assert text =~ "▶"
    end

    test "selected item has reverse style" do
      state = Sidebar.init([])

      {_widget, _props, children} = Sidebar.view(state)
      [first_label | _rest] = children
      {Label, props} = first_label

      assert props.style == :reverse
    end

    test "unselected domains have bold style" do
      state = Sidebar.init([])
      # Ensure we have multiple domains
      state = %{state | selected_index: 0}

      {_widget, _props, children} = Sidebar.view(state)

      # Find an unselected domain
      unselected_domain =
        children
        |> Enum.with_index()
        |> Enum.find(fn {{Label, %{text: text}}, idx} ->
          idx != state.selected_index && (text =~ "▼" || text =~ "▶")
        end)

      if unselected_domain do
        {{Label, props}, _idx} = unselected_domain
        assert props.style == :bold
      end
    end

    test "selected resource shows → indicator" do
      state = Sidebar.init([])
      # Select first resource (index 1, since 0 is domain)
      state = %{state | selected_index: 1}

      {_widget, _props, children} = Sidebar.view(state)
      selected_label = Enum.at(children, 1)
      {Label, %{text: text}} = selected_label

      assert text =~ "→"
    end

    test "unselected resources show no → indicator" do
      state = Sidebar.init([])
      # Select first resource
      state = %{state | selected_index: 1}

      {_widget, _props, children} = Sidebar.view(state)
      # Check third item (should be unselected resource)
      if length(children) > 2 do
        third_label = Enum.at(children, 2)
        {Label, %{text: text}} = third_label
        refute text =~ "→"
      end
    end

    test "resources are indented" do
      state = Sidebar.init([])

      {_widget, _props, children} = Sidebar.view(state)
      # Find a resource label
      resource_label =
        Enum.find(children, fn
          {Label, %{text: text}} -> text =~ "User" || text =~ "Profile"
          _ -> false
        end)

      assert resource_label != nil
      {Label, %{text: text}} = resource_label
      # Resources should start with spaces or arrow + spaces
      assert text =~ ~r/^\s/
    end
  end

  describe "event_to_msg/2 - keyboard navigation" do
    test "Down arrow generates move_selection :down message" do
      state = Sidebar.init([])
      event = %Event.Key{key: :arrow_down}

      assert Sidebar.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "Up arrow generates move_selection :up message" do
      state = Sidebar.init([])
      event = %Event.Key{key: :arrow_up}

      assert Sidebar.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end

    test "Right arrow generates expand_current message" do
      state = Sidebar.init([])
      event = %Event.Key{key: :arrow_right}

      assert Sidebar.event_to_msg(event, state) == {:msg, :expand_current}
    end

    test "Left arrow generates collapse_current message" do
      state = Sidebar.init([])
      event = %Event.Key{key: :arrow_left}

      assert Sidebar.event_to_msg(event, state) == {:msg, :collapse_current}
    end

    test "Enter key generates select_current message" do
      state = Sidebar.init([])
      event = %Event.Key{key: :enter}

      assert Sidebar.event_to_msg(event, state) == {:msg, :select_current}
    end

    test "j key generates move_selection :down message (vim-style)" do
      state = Sidebar.init([])
      event = %Event.Key{key: :char, char: "j"}

      assert Sidebar.event_to_msg(event, state) == {:msg, {:move_selection, :down}}
    end

    test "k key generates move_selection :up message (vim-style)" do
      state = Sidebar.init([])
      event = %Event.Key{key: :char, char: "k"}

      assert Sidebar.event_to_msg(event, state) == {:msg, {:move_selection, :up}}
    end

    test "other keys are ignored" do
      state = Sidebar.init([])
      event = %Event.Key{key: :char, char: "x"}

      assert Sidebar.event_to_msg(event, state) == :ignore
    end
  end

  describe "update/2 - navigation" do
    test "move_selection :down increments selected_index" do
      state = Sidebar.init([])
      initial_index = state.selected_index

      {new_state, _commands} = Sidebar.update({:move_selection, :down}, state)

      assert new_state.selected_index == initial_index + 1
    end

    test "move_selection :up decrements selected_index" do
      state = Sidebar.init([])
      state = %{state | selected_index: 2}

      {new_state, _commands} = Sidebar.update({:move_selection, :up}, state)

      assert new_state.selected_index == 1
    end

    test "move_selection :down wraps at end" do
      state = Sidebar.init([])
      visible_items = length(Enum.flat_map(state.domains, fn d -> if MapSet.member?(state.expanded_domains, d.name), do: [d.name | d.resources], else: [d.name] end))
      state = %{state | selected_index: visible_items - 1}

      {new_state, _commands} = Sidebar.update({:move_selection, :down}, state)

      assert new_state.selected_index == 0
    end

    test "move_selection :up wraps at start" do
      state = Sidebar.init([])
      state = %{state | selected_index: 0}
      visible_items = length(Enum.flat_map(state.domains, fn d -> if MapSet.member?(state.expanded_domains, d.name), do: [d.name | d.resources], else: [d.name] end))

      {new_state, _commands} = Sidebar.update({:move_selection, :up}, state)

      assert new_state.selected_index == visible_items - 1
    end
  end

  describe "update/2 - expand/collapse" do
    test "expand_current expands collapsed domain" do
      state = Sidebar.init([])
      # Blog is collapsed by default, find its index
      visible_items = Enum.flat_map(state.domains, fn d ->
        if MapSet.member?(state.expanded_domains, d.name) do
          [{:domain, d.name} | Enum.map(d.resources, fn r -> {:resource, d.name, r} end)]
        else
          [{:domain, d.name}]
        end
      end)

      blog_index = Enum.find_index(visible_items, fn
        {:domain, "Blog"} -> true
        _ -> false
      end)

      state = %{state | selected_index: blog_index}
      refute MapSet.member?(state.expanded_domains, "Blog")

      {new_state, _commands} = Sidebar.update(:expand_current, state)

      assert MapSet.member?(new_state.expanded_domains, "Blog")
    end

    test "expand_current does nothing if already expanded" do
      state = Sidebar.init([])
      state = %{state | selected_index: 0}  # Accounts is already expanded

      {new_state, _commands} = Sidebar.update(:expand_current, state)

      assert new_state.expanded_domains == state.expanded_domains
    end

    test "collapse_current collapses expanded domain" do
      state = Sidebar.init([])
      state = %{state | selected_index: 0}  # Accounts is expanded
      assert MapSet.member?(state.expanded_domains, "Accounts")

      {new_state, _commands} = Sidebar.update(:collapse_current, state)

      refute MapSet.member?(new_state.expanded_domains, "Accounts")
    end

    test "collapse_current does nothing if already collapsed" do
      state = Sidebar.init([])
      # Find Blog domain index
      visible_items = Enum.flat_map(state.domains, fn d ->
        if MapSet.member?(state.expanded_domains, d.name) do
          [{:domain, d.name} | Enum.map(d.resources, fn r -> {:resource, d.name, r} end)]
        else
          [{:domain, d.name}]
        end
      end)

      blog_index = Enum.find_index(visible_items, fn
        {:domain, "Blog"} -> true
        _ -> false
      end)

      state = %{state | selected_index: blog_index}
      refute MapSet.member?(state.expanded_domains, "Blog")

      {new_state, _commands} = Sidebar.update(:collapse_current, state)

      assert new_state.expanded_domains == state.expanded_domains
    end

    test "collapse_current on resource collapses parent domain" do
      state = Sidebar.init([])
      state = %{state | selected_index: 1}  # First resource under Accounts

      {new_state, _commands} = Sidebar.update(:collapse_current, state)

      refute MapSet.member?(new_state.expanded_domains, "Accounts")
      # Should move selection to domain header
      visible_items_after = Enum.flat_map(new_state.domains, fn d ->
        if MapSet.member?(new_state.expanded_domains, d.name) do
          [{:domain, d.name} | Enum.map(d.resources, fn r -> {:resource, d.name, r} end)]
        else
          [{:domain, d.name}]
        end
      end)
      assert Enum.at(visible_items_after, new_state.selected_index) == {:domain, "Accounts"}
    end
  end

  describe "update/2 - selection" do
    test "select_current on resource sends parent_msg command" do
      state = Sidebar.init([])
      state = %{state | selected_index: 1}  # First resource under Accounts

      {_new_state, commands} = Sidebar.update(:select_current, state)

      assert [{:parent_msg, {:select_resource, "Accounts", _resource}}] = commands
    end

    test "select_current on domain toggles expand/collapse" do
      state = Sidebar.init([])
      # Find Blog (collapsed)
      visible_items = Enum.flat_map(state.domains, fn d ->
        if MapSet.member?(state.expanded_domains, d.name) do
          [{:domain, d.name} | Enum.map(d.resources, fn r -> {:resource, d.name, r} end)]
        else
          [{:domain, d.name}]
        end
      end)

      blog_index = Enum.find_index(visible_items, fn
        {:domain, "Blog"} -> true
        _ -> false
      end)

      state = %{state | selected_index: blog_index}
      refute MapSet.member?(state.expanded_domains, "Blog")

      {new_state, _commands} = Sidebar.update(:select_current, state)

      assert MapSet.member?(new_state.expanded_domains, "Blog")
    end
  end

  describe "integration" do
    test "navigating and expanding domains works end-to-end" do
      state = Sidebar.init([])

      # Start at top (Accounts - expanded)
      assert state.selected_index == 0

      # Move down to first resource
      {state, _} = Sidebar.update({:move_selection, :down}, state)
      assert state.selected_index == 1

      # Move down through resources
      {state, _} = Sidebar.update({:move_selection, :down}, state)
      {state, _} = Sidebar.update({:move_selection, :down}, state)
      {state, _} = Sidebar.update({:move_selection, :down}, state)

      # Should now be at Blog domain (collapsed)
      assert state.selected_index == 4

      # Expand Blog
      {state, _} = Sidebar.update(:expand_current, state)
      assert MapSet.member?(state.expanded_domains, "Blog")

      # Move to Blog's first resource
      {state, _} = Sidebar.update({:move_selection, :down}, state)

      # Select it
      {_state, commands} = Sidebar.update(:select_current, state)
      assert [{:parent_msg, {:select_resource, "Blog", _resource}}] = commands
    end

    test "vim-style navigation works" do
      state = Sidebar.init([])
      initial_index = state.selected_index

      # j to move down
      result = Sidebar.event_to_msg(%Event.Key{key: :char, char: "j"}, state)
      assert result == {:msg, {:move_selection, :down}}
      {state, _} = Sidebar.update({:move_selection, :down}, state)
      assert state.selected_index == initial_index + 1

      # k to move up
      result = Sidebar.event_to_msg(%Event.Key{key: :char, char: "k"}, state)
      assert result == {:msg, {:move_selection, :up}}
      {state, _} = Sidebar.update({:move_selection, :up}, state)
      assert state.selected_index == initial_index
    end

    test "collapsed domain resources are not visible" do
      state = Sidebar.init([])

      # Blog is collapsed, so its resources shouldn't appear in visible items
      {_widget, _props, children} = Sidebar.view(state)

      # Count items
      visible_count = length(children)

      # Should have: Accounts (domain) + 3 resources + Blog (domain) + Shop (domain)
      # = 6 items (not including Blog's 3 resources)
      assert visible_count == 6
    end
  end
end
