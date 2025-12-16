defmodule AshAdminTui.Components.Sidebar do
  @moduledoc """
  Sidebar Navigation Component for AshAdmin TUI.

  The sidebar provides hierarchical navigation through domains and resources using
  a tree-like structure with expand/collapse functionality and keyboard navigation.

  ## State Structure

  ```elixir
  %{
    domains: [
      %{name: "Accounts", resources: ["User", "Profile"]},
      %{name: "Blog", resources: ["Post", "Comment"]}
    ],
    selected_index: 0,          # Index in flattened visible list
    expanded_domains: MapSet.new(["Accounts"])  # Set of expanded domain names
  }
  ```

  ## Navigation

  - Up/Down arrows (or j/k): Navigate through visible items
  - Right arrow: Expand collapsed domain under cursor
  - Left arrow: Collapse expanded domain under cursor
  - Enter: Select resource (sends message to parent)
  - Selection wraps at boundaries

  ## Visual Indicators

  - ▼ Expanded domain
  - ▶ Collapsed domain
  - → Selected item (highlighted)
  """

  alias TermUI.Event
  alias TermUI.Widget.{Label, VStack}

  @doc """
  Initializes the sidebar component state.

  ## Examples

      iex> state = AshAdminTui.Components.Sidebar.init([])
      iex> is_list(state.domains)
      true
      iex> is_integer(state.selected_index)
      true
  """
  @spec init(keyword()) :: map()
  def init(_opts) do
    # Mock data for Phase 2 - will be replaced with real Ash domains in Phase 3
    domains = [
      %{name: "Accounts", resources: ["User", "Profile", "Session"]},
      %{name: "Blog", resources: ["Post", "Comment", "Tag"]},
      %{name: "Shop", resources: ["Product", "Order", "Cart"]}
    ]

    %{
      domains: domains,
      selected_index: 0,
      expanded_domains: MapSet.new(["Accounts"])  # First domain expanded by default
    }
  end

  @doc """
  Converts terminal events to navigation messages.

  Maps arrow keys and vim-style keys to navigation messages.
  """
  @spec event_to_msg(Event.t(), map()) :: {:msg, any()} | :ignore
  def event_to_msg(%Event.Key{key: :arrow_down}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :arrow_up}, _state), do: {:msg, {:move_selection, :up}}
  def event_to_msg(%Event.Key{key: :arrow_right}, _state), do: {:msg, :expand_current}
  def event_to_msg(%Event.Key{key: :arrow_left}, _state), do: {:msg, :collapse_current}
  def event_to_msg(%Event.Key{key: :enter}, _state), do: {:msg, :select_current}

  # Vim-style navigation
  def event_to_msg(%Event.Key{key: :char, char: "j"}, _state), do: {:msg, {:move_selection, :down}}
  def event_to_msg(%Event.Key{key: :char, char: "k"}, _state), do: {:msg, {:move_selection, :up}}

  def event_to_msg(_event, _state), do: :ignore

  @doc """
  Updates sidebar state based on navigation messages.

  Handles movement, expand/collapse, and selection.
  """
  @spec update(any(), map()) :: {map(), list()}
  def update({:move_selection, direction}, state) do
    visible_items = get_visible_items(state)
    max_index = length(visible_items) - 1

    new_index =
      case direction do
        :down ->
          if state.selected_index >= max_index do
            0  # Wrap to top
          else
            state.selected_index + 1
          end

        :up ->
          if state.selected_index <= 0 do
            max_index  # Wrap to bottom
          else
            state.selected_index - 1
          end
      end

    {%{state | selected_index: new_index}, []}
  end

  def update(:expand_current, state) do
    visible_items = get_visible_items(state)
    current_item = Enum.at(visible_items, state.selected_index)

    case current_item do
      {:domain, domain_name} ->
        # Expand this domain if it's collapsed
        if MapSet.member?(state.expanded_domains, domain_name) do
          {state, []}  # Already expanded
        else
          new_expanded = MapSet.put(state.expanded_domains, domain_name)
          {%{state | expanded_domains: new_expanded}, []}
        end

      _ ->
        {state, []}  # Not a domain, no action
    end
  end

  def update(:collapse_current, state) do
    visible_items = get_visible_items(state)
    current_item = Enum.at(visible_items, state.selected_index)

    case current_item do
      {:domain, domain_name} ->
        # Collapse this domain if it's expanded
        if MapSet.member?(state.expanded_domains, domain_name) do
          new_expanded = MapSet.delete(state.expanded_domains, domain_name)
          {%{state | expanded_domains: new_expanded}, []}
        else
          {state, []}  # Already collapsed
        end

      {:resource, _domain_name, _resource_name} ->
        # If on a resource, collapse its parent domain
        domain = find_parent_domain(state, state.selected_index)

        if domain && MapSet.member?(state.expanded_domains, domain) do
          new_expanded = MapSet.delete(state.expanded_domains, domain)
          # Move selection to the domain header
          visible_items_before = get_visible_items(state)
          domain_index = Enum.find_index(visible_items_before, fn item ->
            item == {:domain, domain}
          end)
          new_index = domain_index || state.selected_index

          {%{state | expanded_domains: new_expanded, selected_index: new_index}, []}
        else
          {state, []}
        end
    end
  end

  def update(:select_current, state) do
    visible_items = get_visible_items(state)
    current_item = Enum.at(visible_items, state.selected_index)

    case current_item do
      {:resource, domain_name, resource_name} ->
        # Send selection message to parent
        {state, [{:parent_msg, {:select_resource, domain_name, resource_name}}]}

      {:domain, _domain_name} ->
        # Toggle expand/collapse on Enter for domains
        update(:expand_current, state)
    end
  end

  def update(_msg, state) do
    {state, []}
  end

  @doc """
  Renders the sidebar tree structure.

  Displays domains and their resources with appropriate expand/collapse indicators
  and selection highlighting.
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    visible_items = get_visible_items(state)

    labels =
      visible_items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        render_item(item, index == state.selected_index, state)
      end)

    {VStack, %{}, labels}
  end

  # Private helper functions

  defp get_visible_items(state) do
    state.domains
    |> Enum.flat_map(fn domain ->
      domain_item = {:domain, domain.name}
      is_expanded = MapSet.member?(state.expanded_domains, domain.name)

      if is_expanded do
        resource_items =
          domain.resources
          |> Enum.map(fn resource -> {:resource, domain.name, resource} end)

        [domain_item | resource_items]
      else
        [domain_item]
      end
    end)
  end

  defp render_item({:domain, name}, selected, state) do
    is_expanded = MapSet.member?(state.expanded_domains, name)
    icon = if is_expanded, do: "▼", else: "▶"
    text = "#{icon} #{name}"
    style = if selected, do: :reverse, else: :bold

    {Label, %{text: text, style: style}}
  end

  defp render_item({:resource, _domain, name}, selected, _state) do
    prefix = if selected, do: "  → ", else: "    "
    text = "#{prefix}#{name}"
    style = if selected, do: :reverse, else: :normal

    {Label, %{text: text, style: style}}
  end

  defp find_parent_domain(state, resource_index) do
    visible_items = get_visible_items(state)

    # Walk backwards from current position to find parent domain
    visible_items
    |> Enum.take(resource_index)
    |> Enum.reverse()
    |> Enum.find_value(fn
      {:domain, domain_name} -> domain_name
      _ -> nil
    end)
  end
end
