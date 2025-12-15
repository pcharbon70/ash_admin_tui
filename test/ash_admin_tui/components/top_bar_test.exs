defmodule AshAdminTui.Components.TopBarTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Components.TopBar

  alias AshAdminTui.Components.TopBar
  alias TermUI.Widget.{VStack, HStack, Label, Spacer}

  describe "view/1" do
    test "renders two-line layout in VStack" do
      state = %{
        navigation: %{domain: "Accounts", resource: "User", record_id: nil},
        actor: %{name: "John Doe", role: "admin"},
        tenant: %{name: "ACME Corp"},
        width: 80
      }

      {widget, _props, children} = TopBar.view(state)

      assert widget == VStack
      assert length(children) == 2
    end

    test "line 1 contains application title and actor info" do
      state = %{
        navigation: %{domain: "Accounts", resource: "User", record_id: nil},
        actor: %{name: "John Doe", role: "admin"},
        tenant: %{name: "ACME Corp"},
        width: 80
      }

      {VStack, _props, [line1 | _rest]} = TopBar.view(state)
      {HStack, _hprops, children} = line1

      # Extract text from labels
      texts = extract_label_texts(children)

      assert "AshAdmin TUI" in texts
      assert "Actor: John Doe (admin)" in texts
    end

    test "line 2 contains breadcrumb and tenant info" do
      state = %{
        navigation: %{domain: "Accounts", resource: "User", record_id: nil},
        actor: %{name: "John Doe", role: "admin"},
        tenant: %{name: "ACME Corp"},
        width: 80
      }

      {VStack, _props, [_line1, line2]} = TopBar.view(state)
      {HStack, _hprops, children} = line2

      # Extract text from labels
      texts = extract_label_texts(children)

      assert "Accounts › User" in texts
      assert "Tenant: ACME Corp" in texts
    end

    test "renders correctly without actor" do
      state = %{
        navigation: %{domain: "Home", resource: nil, record_id: nil},
        actor: nil,
        tenant: nil,
        width: 80
      }

      {VStack, _props, [line1, line2]} = TopBar.view(state)

      # Line 1 should show "Actor: None"
      {HStack, _props1, children1} = line1
      texts1 = extract_label_texts(children1)
      assert "Actor: None" in texts1

      # Line 2 should show "Tenant: None"
      {HStack, _props2, children2} = line2
      texts2 = extract_label_texts(children2)
      assert "Tenant: None" in texts2
    end

    test "actor display formats correctly" do
      state = %{
        navigation: %{domain: "Home", resource: nil, record_id: nil},
        actor: %{name: "Jane Smith", role: "viewer"},
        tenant: nil,
        width: 80
      }

      {VStack, _props, [line1 | _rest]} = TopBar.view(state)
      {HStack, _props, children} = line1

      texts = extract_label_texts(children)
      assert "Actor: Jane Smith (viewer)" in texts
    end

    test "tenant display formats correctly" do
      state = %{
        navigation: %{domain: "Home", resource: nil, record_id: nil},
        actor: nil,
        tenant: %{name: "XYZ Organization"},
        width: 80
      }

      {VStack, _props, [_line1, line2]} = TopBar.view(state)
      {HStack, _props, children} = line2

      texts = extract_label_texts(children)
      assert "Tenant: XYZ Organization" in texts
    end
  end

  describe "format_breadcrumb/2" do
    test "shows domain and resource for list view" do
      state = %{
        navigation: %{domain: "Accounts", resource: "User", record_id: nil}
      }

      breadcrumb = TopBar.format_breadcrumb(state, 80)
      assert breadcrumb == "Accounts › User"
    end

    test "includes record ID for detail view" do
      state = %{
        navigation: %{domain: "Accounts", resource: "User", record_id: 123}
      }

      breadcrumb = TopBar.format_breadcrumb(state, 80)
      assert breadcrumb == "Accounts › User › #123"
    end

    test "shows 'Home' when navigation is not set" do
      state = %{}

      breadcrumb = TopBar.format_breadcrumb(state, 80)
      assert breadcrumb == "Home"
    end

    test "truncates long domain names with ellipsis" do
      state = %{
        navigation: %{
          domain: "VeryLongDomainNameThatExceedsWidth",
          resource: "User",
          record_id: nil
        }
      }

      breadcrumb = TopBar.format_breadcrumb(state, 30)

      # Should be truncated to fit within 30 characters
      assert String.length(breadcrumb) <= 30
      # Should still contain the resource name
      assert breadcrumb =~ "User"
      # Should contain ellipsis indicating truncation
      assert breadcrumb =~ "..."
    end

    test "truncates long resource names when domain is also long" do
      state = %{
        navigation: %{
          domain: "LongDomainName",
          resource: "VeryLongResourceName",
          record_id: nil
        }
      }

      breadcrumb = TopBar.format_breadcrumb(state, 20)

      assert String.length(breadcrumb) <= 20
      assert breadcrumb =~ "..."
    end

    test "handles three-part breadcrumb with record ID" do
      state = %{
        navigation: %{
          domain: "Accounts",
          resource: "User",
          record_id: 999
        }
      }

      breadcrumb = TopBar.format_breadcrumb(state, 80)
      assert breadcrumb == "Accounts › User › #999"
    end

    test "truncates three-part breadcrumb when too long" do
      state = %{
        navigation: %{
          domain: "VeryLongDomainName",
          resource: "VeryLongResourceName",
          record_id: 12345
        }
      }

      breadcrumb = TopBar.format_breadcrumb(state, 30)

      # Should be truncated
      assert String.length(breadcrumb) <= 30
      # Should prioritize keeping the record ID
      assert breadcrumb =~ "#12345"
    end

    test "preserves full breadcrumb when it fits" do
      state = %{
        navigation: %{domain: "Blog", resource: "Post", record_id: 5}
      }

      breadcrumb = TopBar.format_breadcrumb(state, 80)
      assert breadcrumb == "Blog › Post › #5"
    end
  end

  describe "integration" do
    test "complete top bar rendering with all context" do
      state = %{
        navigation: %{domain: "Blog", resource: "Post", record_id: 42},
        actor: %{name: "Alice Cooper", role: "editor"},
        tenant: %{name: "TechCorp"},
        width: 80
      }

      {VStack, _props, [line1, line2]} = TopBar.view(state)

      # Verify line 1
      {HStack, _props1, children1} = line1
      texts1 = extract_label_texts(children1)
      assert "AshAdmin TUI" in texts1
      assert "Actor: Alice Cooper (editor)" in texts1

      # Verify line 2
      {HStack, _props2, children2} = line2
      texts2 = extract_label_texts(children2)
      assert "Blog › Post › #42" in texts2
      assert "Tenant: TechCorp" in texts2
    end

    test "adapts to narrow terminal width" do
      state = %{
        navigation: %{
          domain: "VeryLongDomainName",
          resource: "VeryLongResourceName",
          record_id: nil
        },
        actor: %{name: "User With Very Long Name", role: "administrator"},
        tenant: %{name: "Organization With Very Long Name"},
        width: 50
      }

      # Should not crash with narrow width
      {VStack, _props, [line1, line2]} = TopBar.view(state)

      # Verify it produces valid output
      assert is_tuple(line1)
      assert is_tuple(line2)
    end
  end

  # Helper function to extract text from Label widgets
  defp extract_label_texts(children) do
    Enum.flat_map(children, fn
      {Label, %{text: text}} -> [text]
      {Label, %{text: text}, _} -> [text]
      {Spacer, _} -> []
      {Spacer, _, _} -> []
      _ -> []
    end)
  end
end
