# Summary: Section 2.3 - Status Bar Component

**Task ID**: Section 2.3
**Branch**: feature/2.3
**Status**: Completed
**Date**: 2025-12-16

## Overview

Section 2.3 implements the Status Bar Component for AshAdmin TUI, providing context-sensitive keyboard shortcut hints and transient toast notifications. The status bar dynamically displays relevant shortcuts based on the current focus (sidebar or content) and view type (list, detail, form), while also supporting success/error toast messages that auto-dismiss and can be manually cleared.

## Objectives

The primary objectives were to:

1. Implement Status Bar Rendering with context-sensitive shortcuts (task 2.3.1)
2. Implement Toast Notification System with auto-dismiss (task 2.3.2)
3. Write comprehensive unit tests for all status bar functionality
4. Update existing tests to work with new Layout state structure

## Implementation Summary

### Files Created

1. **lib/ash_admin_tui/components/status_bar.ex** (177 lines)
   - Status Bar component with context-sensitive shortcut display
   - Toast notification system with success/error types
   - Color coding: green for success (✓), red for error (✗)
   - Auto-dismiss with countdown timer
   - Functions: init/1, view/1, show_toast/4, dismiss_toast/1, check_toast_expiry/1

2. **test/ash_admin_tui/components/status_bar_test.exs** (364 lines)
   - 35 comprehensive unit tests for StatusBar component
   - Tests for shortcut rendering (9 tests)
   - Tests for toast rendering and behavior (11 tests)
   - Tests for toast management functions (9 tests)
   - Integration tests (6 tests)

### Files Modified

1. **lib/ash_admin_tui/components/layout.ex**
   - Added StatusBar alias import
   - Added view and status_bar state fields to init/1
   - Updated render_status_bar/3 to use StatusBar component
   - Passes focus and view state to StatusBar

2. **test/ash_admin_tui/components/layout_test.exs**
   - Updated minimal_state helper to include view and status_bar fields
   - Updated init/1 test to verify new state fields
   - Ensures all tests work with updated state structure

## Technical Implementation

### 2.3.1 Status Bar Rendering

The status bar displays context-appropriate keyboard shortcuts based on the current application state:

**Shortcut Mappings**:

```elixir
# Sidebar focus
"[↑↓] Navigate [←→] Expand [Enter] Select [Tab] Switch Focus [Q] Quit"

# Content focus - List view
"[↑↓] Navigate [Enter] View [N]ew [E]dit [D]elete [Tab] Switch Focus [Q] Quit"

# Content focus - Detail view
"[E]dit [D]elete [B]ack [A]ctions [Tab] Switch Focus [Q] Quit"

# Content focus - Form view
"[Tab] Next Field [Shift+Tab] Prev Field [F5] Submit [Esc] Cancel [Q] Quit"

# Default (unknown state)
"[Tab] Switch Focus [Q] Quit"
```

**Implementation Pattern**:

```elixir
def view(%{toast: toast} = _state) when not is_nil(toast) do
  # When toast is active, show toast instead of shortcuts
  render_toast(toast)
end

def view(state) do
  # Otherwise, show context-appropriate shortcuts
  shortcuts = get_shortcuts(state.focus, state.view)
  {Label, %{text: shortcuts}}
end

defp get_shortcuts(:sidebar, _view) do
  "[↑↓] Navigate [←→] Expand [Enter] Select [Tab] Switch Focus [Q] Quit"
end

defp get_shortcuts(:content, :list) do
  "[↑↓] Navigate [Enter] View [N]ew [E]dit [D]elete [Tab] Switch Focus [Q] Quit"
end

# ... more mappings
```

**Key Features**:
- Pattern matching on focus and view for appropriate shortcuts
- Toast takes priority over shortcuts when active
- Simple, readable text format with bracket notation for keys
- Context-aware help reduces cognitive load for users

### 2.3.2 Toast Notification System

Toast notifications provide transient feedback for user actions with automatic dismissal and manual override:

**Toast State Structure**:

```elixir
%{
  message: "Record created successfully",
  type: :success | :error,
  expires_at: timestamp,  # System.monotonic_time(:millisecond)
  duration: 3000          # Duration in milliseconds
}
```

**Visual Formatting**:

```elixir
# Success toast
"✓ Record created successfully (dismissed in 3s)"  # Green text

# Error toast
"✗ Operation failed (dismissed in 2s)"  # Red text
```

**Core Functions**:

1. **show_toast/4** - Creates a new toast notification
   ```elixir
   def show_toast(state, message, type, duration_ms) do
     expires_at = System.monotonic_time(:millisecond) + duration_ms

     %{state | toast: %{
       message: message,
       type: type,
       expires_at: expires_at,
       duration: duration_ms
     }}
   end
   ```

2. **dismiss_toast/1** - Manually clears the toast
   ```elixir
   def dismiss_toast(state) do
     %{state | toast: nil}
   end
   ```

3. **check_toast_expiry/1** - Auto-dismisses expired toasts
   ```elixir
   def check_toast_expiry(%{toast: toast} = state) do
     now = System.monotonic_time(:millisecond)

     if now >= toast.expires_at do
       dismiss_toast(state)
     else
       state
     end
   end
   ```

4. **render_toast/1** - Renders toast with countdown
   ```elixir
   defp render_toast(%{message: message, type: type, expires_at: expires_at}) do
     icon = if type == :success, do: "✓", else: "✗"
     color = if type == :success, do: :green, else: :red

     # Calculate remaining seconds (rounded up)
     now = System.monotonic_time(:millisecond)
     remaining_ms = max(expires_at - now, 0)
     remaining_sec = div(remaining_ms + 999, 1000)

     text = "#{icon} #{message} (dismissed in #{remaining_sec}s)"
     {Label, %{text: text, color: color}}
   end
   ```

**Countdown Timer**:
- Calculates remaining time in real-time
- Rounds up to next second (1100ms → "2s")
- Shows "0s" at expiry before dismissal
- Provides visual feedback of auto-dismiss timing

**Color Coding**:
- Success: `:green` with checkmark icon (✓)
- Error: `:red` with cross icon (✗)
- Immediate visual distinction between message types

### Integration with Layout

The Layout component manages the status bar state and passes it to the StatusBar component:

**State Management**:

```elixir
# Layout state
%{
  terminal_size: {80, 24},
  focus: :sidebar,
  view: nil,  # Current view type
  status_bar: %{toast: nil},  # StatusBar state
  # ... other fields
}
```

**Rendering**:

```elixir
defp render_status_bar(state, width, height) do
  # Prepare state for StatusBar component
  status_bar_state = %{
    focus: state.focus,
    view: state.view,
    toast: state.status_bar.toast,
    width: width - 4  # Account for border padding
  }

  {Block, %{border: :single, height: height}, [
    StatusBar.view(status_bar_state)
  ]}
end
```

**Phase 2 Approach**:
- Status bar state initialized with no active toast
- View defaults to `nil` (will be updated in later sections)
- Focus managed by Layout component (sidebar/content)
- Toast system ready for integration with user actions in Phase 3

## Test Coverage

### StatusBar Component Tests

**Unit Tests** (35 tests):

1. **Initialization tests** (1 test)
   - Initializes with no active toast

2. **Shortcuts rendering tests** (9 tests)
   - Renders shortcuts for sidebar focus
   - Renders shortcuts for list view focus
   - Renders shortcuts for detail view focus
   - Renders shortcuts for form view focus
   - Renders default shortcuts for unknown view
   - Shortcuts are context-appropriate for each combination

3. **Toast rendering tests** (11 tests)
   - Displays toast message when active
   - Correct color for success type (green with ✓)
   - Correct color for error type (red with ✗)
   - Toast replaces shortcuts while active
   - Shows countdown timer
   - Countdown rounds up remaining time
   - Various display scenarios

4. **Toast management tests** (9 tests)
   - show_toast creates toast with correct properties
   - Sets expiry time based on duration
   - Replaces existing toast
   - dismiss_toast clears active toast
   - Handles nil toast gracefully
   - check_toast_expiry dismisses expired toast
   - Keeps non-expired toast
   - Dismisses toast exactly at expiry time

5. **Integration tests** (6 tests)
   - Complete toast lifecycle
   - Auto-dismiss after expiry
   - Different shortcuts for different contexts
   - End-to-end workflows

**Test Results**:
```
AshAdminTui.Components.StatusBarTest
5 doctests, 35 tests, 0 failures
```

### Updated Layout Tests

**Changes Made**:
- Updated minimal_state helper to include view and status_bar fields
- Updated init/1 test to verify new state fields
- All 22 existing Layout tests continue passing

**Overall Test Results**:
```
11 doctests, 223 tests, 0 failures
Coverage: Maintained (all tests passing)
```

## Challenges and Solutions

### Challenge 1: Toast Priority Over Shortcuts

**Problem**: Need to display toast notifications while not losing shortcut functionality when toast is dismissed.

**Solution**:
- Used pattern matching with guard clause: `def view(%{toast: toast} = _state) when not is_nil(toast)`
- Toast check happens first, falls through to shortcuts when no toast
- Clean separation of concerns between toast and shortcut rendering
- Easy to switch between the two display modes

### Challenge 2: Countdown Timer Accuracy

**Problem**: Toast countdown needs to show remaining seconds, but monotonic time is in milliseconds and needs proper rounding.

**Solution**:
- Calculate remaining milliseconds: `remaining_ms = max(expires_at - now, 0)`
- Round up to next second: `div(remaining_ms + 999, 1000)`
- This ensures 1100ms shows "2s" (user-friendly rounding)
- Use `max()` to prevent negative values
- Real-time calculation in render function for accuracy

### Challenge 3: Context-Sensitive Shortcuts

**Problem**: Different shortcuts needed for 6+ different focus/view combinations without code duplication.

**Solution**:
- Implemented `get_shortcuts/2` with pattern matching on (focus, view) tuple
- Each combination has its own clause
- Default fallback for unknown combinations
- Easy to extend with new view types
- Clear, maintainable code structure:

```elixir
defp get_shortcuts(:sidebar, _view) do
  # Sidebar shortcuts (view doesn't matter)
end

defp get_shortcuts(:content, :list) do
  # List view shortcuts
end

defp get_shortcuts(:content, :detail) do
  # Detail view shortcuts
end

# ... more combinations

defp get_shortcuts(_focus, _view) do
  # Default fallback
end
```

### Challenge 4: State Structure Evolution

**Problem**: Adding new state fields (view, status_bar) to Layout component broke existing tests.

**Solution**:
- Updated `minimal_state/1` helper in Layout tests to include new fields
- Single source of truth for test state structure
- All existing tests automatically work with new structure
- Easy to add more fields in the future
- Demonstrates importance of test helpers for maintainability

## Verification

All implementation requirements have been verified:

### Task 2.3.1: Status Bar Rendering ✅

- [x] Created lib/ash_admin_tui/components/status_bar.ex module
- [x] Implemented view/1 taking focus and view state as input
- [x] Defined shortcut mappings for each focus/view combination
- [x] Render shortcuts in format "[Key] Action [Key] Action"
- [x] For sidebar focus: show navigation, expand, select, quit shortcuts
- [x] For list view focus: show navigate, view, new, edit, delete shortcuts
- [x] For detail view focus: show edit, delete, back, actions shortcuts

### Task 2.3.2: Toast Notification System ✅

- [x] Add toast state: `%{message, type, expires_at, duration}`
- [x] Implement show_toast/4 function taking message, type, and duration
- [x] When toast is active, replace shortcuts with toast message
- [x] Apply color coding: green for success, red for error
- [x] Add countdown timer showing "dismissed in Xs"
- [x] Auto-dismiss toast after duration expires (via check_toast_expiry/1)
- [x] Allow manual dismiss with dismiss_toast/1

### Unit Tests ✅

- [x] Test StatusBar.view/1 renders shortcuts for sidebar focus
- [x] Test StatusBar.view/1 renders shortcuts for list view focus
- [x] Test StatusBar.view/1 renders shortcuts for detail view focus
- [x] Test shortcuts are context-appropriate for each view
- [x] Test show_toast/3 displays toast message
- [x] Test toast has correct color for success/error types
- [x] Test toast auto-dismisses after duration
- [x] Test toast dismisses on key press (dismiss_toast function)
- [x] Test toast replaces shortcuts while active

## Phase 2 Progress

Section 2.3 completes the third part of Phase 2:

- [x] **2.1**: Layout Manager Component
- [x] **2.2**: Top Bar Component
- [x] **2.3**: Status Bar Component
- [ ] 2.4: Sidebar Navigation Component
- [ ] 2.5: Content Area Router
- [ ] 2.6: List View Component
- [ ] 2.7: Detail View Component
- [ ] 2.8: Form View Component
- [ ] 2.9: Integration Tests

The status bar provides essential user guidance and feedback mechanism for all future interactions.

## Integration with Existing Code

The status bar integrates seamlessly with Phase 2 infrastructure:

**Layout Integration**:
- StatusBar replaces placeholder "[Tab] Switch Focus [Q] Quit" text
- Layout manages status_bar state and passes it to StatusBar component
- Focus and view state automatically propagate to status bar
- Toast state ready for action feedback in future sections

**State Management**:
- StatusBar state lives in Layout component
- Simple structure: `%{toast: nil}` or `%{toast: %{message, type, ...}}`
- Easy to trigger toasts from anywhere in Layout/Root hierarchy
- Clean separation between status bar logic and layout logic

**Testing**:
- All existing tests updated and passing
- New test helper pattern (minimal_state) improves maintainability
- Comprehensive coverage of toast lifecycle and shortcuts

## Future Integration Points

The status bar is designed for easy integration with user actions:

**Toast Triggers** (Phase 3+):
```elixir
# Success feedback
status_bar = StatusBar.show_toast(
  state.status_bar,
  "Record created successfully",
  :success,
  3000
)

# Error feedback
status_bar = StatusBar.show_toast(
  state.status_bar,
  "Failed to delete record",
  :error,
  5000
)
```

**View Changes**:
```elixir
# When view changes, shortcuts automatically update
state = %{state | view: :list}
# Status bar will now show list view shortcuts
```

**Event Handling** (future):
```elixir
# Any key press when toast is active dismisses it
def update(:key_press, state) when not is_nil(state.status_bar.toast) do
  new_status_bar = StatusBar.dismiss_toast(state.status_bar)
  {%{state | status_bar: new_status_bar}, []}
end
```

**Periodic Updates** (future):
```elixir
# Check toast expiry on timer
def update(:tick, state) do
  new_status_bar = StatusBar.check_toast_expiry(state.status_bar)
  {%{state | status_bar: new_status_bar}, []}
end
```

## Files Modified Summary

| File | Changes | Lines |
|------|---------|-------|
| lib/ash_admin_tui/components/status_bar.ex | Created | +177 |
| lib/ash_admin_tui/components/layout.ex | Added StatusBar integration | ~15 changes |
| test/ash_admin_tui/components/status_bar_test.exs | Created | +364 |
| test/ash_admin_tui/components/layout_test.exs | Updated state structure | ~5 changes |

**Total**: 4 files, ~556 insertions, ~15 modifications

## Next Steps

With section 2.3 complete, the following sections can now be implemented:

1. **Section 2.4**: Sidebar Navigation Component - hierarchical domain/resource browsing
2. **Section 2.5**: Content Area Router - view switching and state management
3. **Sections 2.6-2.8**: View components (List, Detail, Form) - data display and interaction

The status bar now provides:
- Context-aware help for each view
- User feedback mechanism via toasts
- Foundation for action confirmations and error reporting

## Conclusion

Section 2.3 successfully implements the Status Bar Component, completing the contextual help and feedback system for AshAdmin TUI. The implementation:

- **Provides contextual guidance**: Different shortcuts for each focus/view combination
- **Delivers user feedback**: Toast notifications with success/error states
- **Follows TermUI patterns**: Clean Elm Architecture with composable widgets
- **Maintains quality**: All 223 tests passing, comprehensive coverage
- **Enables future work**: Ready for action feedback and view navigation

The status bar transforms AshAdmin TUI into a guided experience where users always know what actions are available and receive immediate feedback on their operations. Combined with the top bar's session context (section 2.2) and layout manager's visual structure (section 2.1), AshAdmin TUI now provides a complete, professional terminal interface framework ready for content and navigation implementation.
