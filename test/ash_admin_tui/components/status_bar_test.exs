defmodule AshAdminTui.Components.StatusBarTest do
  use ExUnit.Case, async: true
  doctest AshAdminTui.Components.StatusBar

  alias AshAdminTui.Components.StatusBar
  alias TermUI.Widget.Label

  describe "init/1" do
    test "initializes with no active toast" do
      state = StatusBar.init([])

      assert state.toast == nil
    end
  end

  describe "view/1 - shortcuts rendering" do
    test "renders shortcuts for sidebar focus" do
      state = %{focus: :sidebar, view: nil, toast: nil, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "Navigate"
      assert props.text =~ "Expand"
      assert props.text =~ "Select"
      assert props.text =~ "Quit"
    end

    test "renders shortcuts for list view focus" do
      state = %{focus: :content, view: :list, toast: nil, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "Navigate"
      assert props.text =~ "View"
      assert props.text =~ "[N]ew"
      assert props.text =~ "[E]dit"
      assert props.text =~ "[D]elete"
    end

    test "renders shortcuts for detail view focus" do
      state = %{focus: :content, view: :detail, toast: nil, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "[E]dit"
      assert props.text =~ "[D]elete"
      assert props.text =~ "[B]ack"
      assert props.text =~ "[A]ctions"
    end

    test "renders shortcuts for form view focus" do
      state = %{focus: :content, view: :form, toast: nil, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "Next Field"
      assert props.text =~ "Prev Field"
      assert props.text =~ "Submit"
      assert props.text =~ "Cancel"
    end

    test "renders default shortcuts for unknown view" do
      state = %{focus: :content, view: :unknown, toast: nil, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "Switch Focus"
      assert props.text =~ "Quit"
    end

    test "shortcuts are context-appropriate for each focus/view combination" do
      # Sidebar focus
      sidebar_state = %{focus: :sidebar, view: nil, toast: nil, width: 80}
      {_, sidebar_props} = StatusBar.view(sidebar_state)
      assert sidebar_props.text =~ "Navigate"
      assert sidebar_props.text =~ "Expand"

      # Content focus with list view
      list_state = %{focus: :content, view: :list, toast: nil, width: 80}
      {_, list_props} = StatusBar.view(list_state)
      assert list_props.text =~ "[N]ew"
      assert list_props.text =~ "[E]dit"

      # Content focus with detail view
      detail_state = %{focus: :content, view: :detail, toast: nil, width: 80}
      {_, detail_props} = StatusBar.view(detail_state)
      assert detail_props.text =~ "[B]ack"
      assert detail_props.text =~ "[A]ctions"
    end
  end

  describe "view/1 - toast rendering" do
    test "displays toast message when toast is active" do
      toast = %{
        message: "Record created successfully",
        type: :success,
        expires_at: System.monotonic_time(:millisecond) + 3000,
        duration: 3000
      }

      state = %{focus: :sidebar, view: nil, toast: toast, width: 80}

      {widget, props} = StatusBar.view(state)

      assert widget == Label
      assert props.text =~ "Record created successfully"
      assert props.text =~ "dismissed in"
      assert props.color == :green
    end

    test "toast has correct color for success type" do
      toast = %{
        message: "Success message",
        type: :success,
        expires_at: System.monotonic_time(:millisecond) + 3000,
        duration: 3000
      }

      state = %{focus: :sidebar, view: nil, toast: toast, width: 80}

      {_, props} = StatusBar.view(state)

      assert props.color == :green
      assert props.text =~ "✓"
    end

    test "toast has correct color for error type" do
      toast = %{
        message: "Error message",
        type: :error,
        expires_at: System.monotonic_time(:millisecond) + 3000,
        duration: 3000
      }

      state = %{focus: :sidebar, view: nil, toast: toast, width: 80}

      {_, props} = StatusBar.view(state)

      assert props.color == :red
      assert props.text =~ "✗"
    end

    test "toast replaces shortcuts while active" do
      toast = %{
        message: "Test toast",
        type: :success,
        expires_at: System.monotonic_time(:millisecond) + 3000,
        duration: 3000
      }

      # Without toast - shows shortcuts
      state_without_toast = %{focus: :sidebar, view: nil, toast: nil, width: 80}
      {_, props_without} = StatusBar.view(state_without_toast)
      assert props_without.text =~ "Navigate"

      # With toast - shows toast message
      state_with_toast = %{focus: :sidebar, view: nil, toast: toast, width: 80}
      {_, props_with} = StatusBar.view(state_with_toast)
      assert props_with.text =~ "Test toast"
      refute props_with.text =~ "Navigate"
    end

    test "toast shows countdown timer" do
      now = System.monotonic_time(:millisecond)

      toast = %{
        message: "Timer test",
        type: :success,
        expires_at: now + 5000,
        duration: 5000
      }

      state = %{focus: :sidebar, view: nil, toast: toast, width: 80}

      {_, props} = StatusBar.view(state)

      # Should show approximately 5 seconds remaining
      assert props.text =~ ~r/dismissed in [45]s/
    end

    test "toast countdown rounds up remaining time" do
      now = System.monotonic_time(:millisecond)

      # 1100ms remaining should show "2s" (rounded up)
      toast = %{
        message: "Round up test",
        type: :success,
        expires_at: now + 1100,
        duration: 3000
      }

      state = %{focus: :sidebar, view: nil, toast: toast, width: 80}

      {_, props} = StatusBar.view(state)

      assert props.text =~ "dismissed in 2s"
    end
  end

  describe "show_toast/4" do
    test "creates toast with correct message and type" do
      state = %{toast: nil}

      new_state = StatusBar.show_toast(state, "Test message", :success, 3000)

      assert new_state.toast.message == "Test message"
      assert new_state.toast.type == :success
      assert new_state.toast.duration == 3000
    end

    test "sets expiry time based on duration" do
      state = %{toast: nil}
      before = System.monotonic_time(:millisecond)

      new_state = StatusBar.show_toast(state, "Test", :success, 3000)

      after_time = System.monotonic_time(:millisecond)

      # expires_at should be approximately now + 3000
      assert new_state.toast.expires_at >= before + 3000
      assert new_state.toast.expires_at <= after_time + 3000
    end

    test "replaces existing toast" do
      state = %{
        toast: %{
          message: "Old toast",
          type: :success,
          expires_at: System.monotonic_time(:millisecond) + 5000,
          duration: 5000
        }
      }

      new_state = StatusBar.show_toast(state, "New toast", :error, 2000)

      assert new_state.toast.message == "New toast"
      assert new_state.toast.type == :error
      assert new_state.toast.duration == 2000
    end
  end

  describe "dismiss_toast/1" do
    test "clears active toast" do
      state = %{
        toast: %{
          message: "Test",
          type: :success,
          expires_at: System.monotonic_time(:millisecond) + 3000,
          duration: 3000
        }
      }

      new_state = StatusBar.dismiss_toast(state)

      assert new_state.toast == nil
    end

    test "handles nil toast gracefully" do
      state = %{toast: nil}

      new_state = StatusBar.dismiss_toast(state)

      assert new_state.toast == nil
    end
  end

  describe "check_toast_expiry/1" do
    test "dismisses expired toast" do
      now = System.monotonic_time(:millisecond)

      state = %{
        toast: %{
          message: "Expired",
          type: :success,
          expires_at: now - 1000,  # Expired 1 second ago
          duration: 3000
        }
      }

      new_state = StatusBar.check_toast_expiry(state)

      assert new_state.toast == nil
    end

    test "keeps non-expired toast" do
      now = System.monotonic_time(:millisecond)

      toast = %{
        message: "Still active",
        type: :success,
        expires_at: now + 5000,  # Expires in 5 seconds
        duration: 5000
      }

      state = %{toast: toast}

      new_state = StatusBar.check_toast_expiry(state)

      assert new_state.toast == toast
    end

    test "handles nil toast" do
      state = %{toast: nil}

      new_state = StatusBar.check_toast_expiry(state)

      assert new_state.toast == nil
    end

    test "dismisses toast exactly at expiry time" do
      now = System.monotonic_time(:millisecond)

      state = %{
        toast: %{
          message: "Expiring now",
          type: :success,
          expires_at: now,
          duration: 3000
        }
      }

      new_state = StatusBar.check_toast_expiry(state)

      assert new_state.toast == nil
    end
  end

  describe "integration" do
    test "complete toast lifecycle" do
      # Start with no toast
      state = StatusBar.init([])
      assert state.toast == nil

      # Show a toast
      state = StatusBar.show_toast(state, "Operation complete", :success, 3000)
      assert state.toast.message == "Operation complete"

      # Render shows toast
      view_state = %{focus: :sidebar, view: nil, toast: state.toast, width: 80}
      {_, props} = StatusBar.view(view_state)
      assert props.text =~ "Operation complete"
      assert props.color == :green

      # Manual dismiss
      state = StatusBar.dismiss_toast(state)
      assert state.toast == nil

      # Render shows shortcuts again
      view_state = %{focus: :sidebar, view: nil, toast: state.toast, width: 80}
      {_, props} = StatusBar.view(view_state)
      assert props.text =~ "Navigate"
    end

    test "auto-dismiss after expiry" do
      now = System.monotonic_time(:millisecond)

      # Create toast that expires very soon
      state = %{
        toast: %{
          message: "Quick toast",
          type: :success,
          expires_at: now + 10,  # Expires in 10ms
          duration: 10
        }
      }

      # Wait for expiry
      Process.sleep(20)

      # Check expiry should dismiss it
      state = StatusBar.check_toast_expiry(state)
      assert state.toast == nil
    end

    test "different shortcuts for different contexts" do
      base_state = %{toast: nil, width: 80}

      # Sidebar
      {_, sidebar_props} = StatusBar.view(Map.merge(base_state, %{focus: :sidebar, view: nil}))
      assert sidebar_props.text =~ "Expand"

      # List view
      {_, list_props} = StatusBar.view(Map.merge(base_state, %{focus: :content, view: :list}))
      assert list_props.text =~ "[N]ew"

      # Detail view
      {_, detail_props} = StatusBar.view(Map.merge(base_state, %{focus: :content, view: :detail}))
      assert detail_props.text =~ "[B]ack"

      # Form view
      {_, form_props} = StatusBar.view(Map.merge(base_state, %{focus: :content, view: :form}))
      assert form_props.text =~ "Submit"
    end
  end
end
