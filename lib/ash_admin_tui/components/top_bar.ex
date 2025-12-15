defmodule AshAdminTui.Components.TopBar do
  @moduledoc """
  Top Bar Component for AshAdmin TUI.

  The top bar displays contextual information about the current session, including:
  - Application title
  - Navigation breadcrumbs showing current location
  - Actor context (current user and role)
  - Tenant context (current tenant/organization)

  ## Layout

  ```
  Line 1: AshAdmin TUI                              Actor: John Doe (admin)
  Line 2: Home › Users                              Tenant: ACME Corp
  ```

  ## State

  The component expects a state map with the following keys:
  - `:navigation` - Navigation state with domain, resource, and optional record_id
  - `:actor` - Actor information with name and role
  - `:tenant` - Tenant information with name
  - `:width` - Terminal width for truncation calculations

  ## Breadcrumb Format

  - List view: "Domain › Resource"
  - Detail view: "Domain › Resource › #123"
  - Truncated: "Very Long Dom... › Resource"
  """

  alias TermUI.Widget.{HStack, Label, Spacer}

  @doc """
  Renders the top bar with session context information.

  Returns a two-line layout with title/actor on line 1 and breadcrumb/tenant on line 2.

  ## Examples

      iex> state = %{
      ...>   navigation: %{domain: "Accounts", resource: "User", record_id: nil},
      ...>   actor: %{name: "John Doe", role: "admin"},
      ...>   tenant: %{name: "ACME Corp"},
      ...>   width: 80
      ...> }
      iex> {widget, _props, _children} = AshAdminTui.Components.TopBar.view(state)
      iex> widget
      TermUI.Widget.VStack
  """
  @spec view(map()) :: TermUI.view_spec()
  def view(state) do
    width = Map.get(state, :width, 80)

    {TermUI.Widget.VStack, %{}, [
      # Line 1: Title and Actor
      render_line_1(state, width),

      # Line 2: Breadcrumb and Tenant
      render_line_2(state, width)
    ]}
  end

  # Private helper functions

  defp render_line_1(state, width) do
    title = "AshAdmin TUI"
    actor_text = format_actor(state)

    # Calculate available space for actor (reserve space for title and padding)
    title_width = String.length(title)
    actor_width = String.length(actor_text)
    spacer_width = max(width - title_width - actor_width - 2, 0)

    {HStack, %{}, [
      {Label, %{text: title, style: :bold}},
      {Spacer, %{width: spacer_width}},
      {Label, %{text: actor_text, style: :dim}}
    ]}
  end

  defp render_line_2(state, width) do
    breadcrumb = format_breadcrumb(state, width)
    tenant_text = format_tenant(state)

    # Calculate available space for tenant
    breadcrumb_width = String.length(breadcrumb)
    tenant_width = String.length(tenant_text)
    spacer_width = max(width - breadcrumb_width - tenant_width - 2, 0)

    {HStack, %{}, [
      {Label, %{text: breadcrumb, style: :dim}},
      {Spacer, %{width: spacer_width}},
      {Label, %{text: tenant_text, style: :dim}}
    ]}
  end

  defp format_actor(%{actor: %{name: name, role: role}}) do
    "Actor: #{name} (#{role})"
  end

  defp format_actor(_state), do: "Actor: None"

  defp format_tenant(%{tenant: %{name: name}}) do
    "Tenant: #{name}"
  end

  defp format_tenant(_state), do: "Tenant: None"

  @doc """
  Formats navigation breadcrumb based on current location.

  ## Examples

      iex> state = %{
      ...>   navigation: %{domain: "Accounts", resource: "User", record_id: nil},
      ...>   width: 80
      ...> }
      iex> AshAdminTui.Components.TopBar.format_breadcrumb(state, 80)
      "Accounts › User"

      iex> state = %{
      ...>   navigation: %{domain: "Accounts", resource: "User", record_id: 123},
      ...>   width: 80
      ...> }
      iex> AshAdminTui.Components.TopBar.format_breadcrumb(state, 80)
      "Accounts › User › #123"

      iex> state = %{
      ...>   navigation: %{domain: "VeryLongDomainName", resource: "VeryLongResourceName", record_id: nil},
      ...>   width: 30
      ...> }
      iex> breadcrumb = AshAdminTui.Components.TopBar.format_breadcrumb(state, 30)
      iex> String.length(breadcrumb) <= 30
      true
  """
  @spec format_breadcrumb(map(), non_neg_integer()) :: String.t()
  def format_breadcrumb(%{navigation: %{domain: domain, resource: resource, record_id: record_id}}, max_width) do
    # Build full breadcrumb
    parts = [domain, resource]
    parts = if record_id, do: parts ++ ["##{record_id}"], else: parts

    breadcrumb = Enum.join(parts, " › ")

    # Truncate if necessary
    if String.length(breadcrumb) > max_width do
      truncate_breadcrumb(parts, max_width)
    else
      breadcrumb
    end
  end

  def format_breadcrumb(_state, _max_width), do: "Home"

  defp truncate_breadcrumb(parts, max_width) do
    # Try to preserve the last part (most specific) and truncate earlier parts
    separator = " › "
    separator_length = String.length(separator)

    case parts do
      [domain, resource] ->
        # For two parts, truncate domain if needed
        resource_width = String.length(resource)
        available_for_domain = max_width - resource_width - separator_length - 3  # 3 for "..."

        if available_for_domain > 0 do
          truncated_domain = String.slice(domain, 0, available_for_domain) <> "..."
          "#{truncated_domain}#{separator}#{resource}"
        else
          # Resource itself is too long, truncate it
          String.slice(resource, 0, max_width - 3) <> "..."
        end

      [domain, resource, record] ->
        # For three parts, preserve record and truncate domain/resource as needed
        record_width = String.length(record)
        available = max_width - record_width - separator_length

        if available > 10 do
          # Enough space for shortened domain/resource
          truncated = truncate_breadcrumb([domain, resource], available)
          "#{truncated}#{separator}#{record}"
        else
          # Only show record
          record
        end

      _ ->
        # Fallback: just truncate the joined string
        String.slice(Enum.join(parts, separator), 0, max_width - 3) <> "..."
    end
  end
end
