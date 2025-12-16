# Phase 2: Core UI Components and Navigation

## Phase Overview

Phase 2 builds the core user interface components and navigation system on the foundation established in Phase 1. This phase transforms the simple welcome screen into a functional admin interface with hierarchical navigation, multiple view types, and keyboard-driven interaction patterns.

The implementation creates a component hierarchy following TermUI's Elm Architecture, with specialized components for layout management, sidebar navigation, and content routing. The navigation system allows browsing domains and resources, while the content area dynamically renders different view types (list, detail, form) based on user selection.

By the end of Phase 2, users will be able to navigate through mock domain/resource structures using keyboard shortcuts, demonstrating the complete UI interaction model that will be integrated with real Ash data in Phase 3.

## 2.1 Layout Manager Component

- [x] **Section 2.1 Complete**

The layout manager orchestrates the physical screen layout, dividing the terminal into regions for different UI components. It uses TermUI's SplitPane widget to create a responsive layout that adapts to terminal size while maintaining proper proportions and minimum dimensions.

### 2.1.1 Implement Layout Component

- [x] **Task 2.1.1 Complete**

Create the layout component that renders the four-section interface structure and manages responsive sizing.

- [x] 2.1.1.1 Create lib/ash_admin_tui/components/layout.ex module
- [x] 2.1.1.2 Define layout state: `%{terminal_size: {width, height}, focus: :sidebar | :content}`
- [x] 2.1.1.3 Implement view/1 with vertical stack containing top bar, split pane, and status bar
- [x] 2.1.1.4 Configure top bar with fixed height of 2 lines
- [x] 2.1.1.5 Configure split pane with sidebar at 25% width (minimum 30 characters)
- [x] 2.1.1.6 Configure status bar with fixed height of 1 line
- [x] 2.1.1.7 Add resize event handling to update terminal_size in state

### 2.1.2 Implement Focus Management

- [x] **Task 2.1.2 Complete**

Build focus management system that tracks which component has keyboard focus and provides visual feedback.

- [x] 2.1.2.1 Add focus state to layout: `:sidebar` or `:content`
- [x] 2.1.2.2 Implement Tab key handling to toggle focus between sidebar and content
- [x] 2.1.2.3 Apply focus styling (highlighted border) to active component
- [x] 2.1.2.4 Route keyboard events to focused component
- [x] 2.1.2.5 Implement focus indicator in status bar showing current focus

### 2.1.3 Unit Tests - Section 2.1

- [x] **Unit Tests 2.1 Complete**

- [x] Test Layout component initializes with correct structure
- [x] Test layout has four sections (top bar, sidebar, content, status bar)
- [x] Test sidebar takes 25% width with 30 char minimum
- [x] Test Tab key toggles focus between sidebar and content
- [x] Test focused component has highlighted border
- [x] Test resize events update terminal_size in state
- [x] Test keyboard events route to focused component

## 2.2 Top Bar Component

- [x] **Section 2.2 Complete**

The top bar displays contextual information about the current session, including application title, navigation breadcrumbs, actor context, and tenant context. It provides at-a-glance awareness of the authorization context.

### 2.2.1 Implement Top Bar Rendering

- [x] **Task 2.2.1 Complete**

Create the top bar component with title and context information display.

- [x] 2.2.1.1 Create lib/ash_admin_tui/components/top_bar.ex module
- [x] 2.2.1.2 Implement view/1 taking session state as input
- [x] 2.2.1.3 Render line 1: application title on left, actor info on right
- [x] 2.2.1.4 Render line 2: breadcrumb navigation on left, tenant info on right
- [x] 2.2.1.5 Format actor display as "Actor: <name> <role>"
- [x] 2.2.1.6 Format tenant display as "Tenant: <name>"
- [x] 2.2.1.7 Add keyboard shortcut hints ([I] for impersonation, [T] for tenant)

### 2.2.2 Implement Breadcrumb Navigation

- [x] **Task 2.2.2 Complete**

Build breadcrumb display showing current navigation path (Domain › Resource › Record ID).

- [x] 2.2.2.1 Accept navigation state from parent component
- [x] 2.2.2.2 Format breadcrumb as "Domain › Resource" for list view
- [x] 2.2.2.3 Format breadcrumb as "Domain › Resource › #ID" for detail view
- [x] 2.2.2.4 Truncate long names with ellipsis if width constrained
- [x] 2.2.2.5 Apply styling to breadcrumb (dimmed or secondary color)

### 2.2.3 Unit Tests - Section 2.2

- [x] **Unit Tests 2.2 Complete**

- [x] Test TopBar.view/1 renders two-line layout
- [x] Test line 1 contains application title and actor info
- [x] Test line 2 contains breadcrumb and tenant info
- [x] Test actor display formats correctly
- [x] Test tenant display formats correctly
- [x] Test breadcrumb shows domain and resource
- [x] Test breadcrumb includes record ID in detail view
- [x] Test long names truncate with ellipsis

## 2.3 Status Bar Component

- [x] **Section 2.3 Complete**

The status bar provides context-sensitive help showing available keyboard shortcuts for the current view. It also displays transient toast notifications for success and error messages.

### 2.3.1 Implement Status Bar Rendering

- [x] **Task 2.3.1 Complete**

Create the status bar component with context-sensitive shortcut display.

- [x] 2.3.1.1 Create lib/ash_admin_tui/components/status_bar.ex module
- [x] 2.3.1.2 Implement view/1 taking focus and view state as input
- [x] 2.3.1.3 Define shortcut mappings for each focus/view combination
- [x] 2.3.1.4 Render shortcuts in format "[Key] Action [Key] Action"
- [x] 2.3.1.5 For sidebar focus: show "[↑↓] Navigate [←→] Expand [Enter] Select [Q] Quit"
- [x] 2.3.1.6 For list view focus: show "[↑↓] Navigate [Enter] View [N]ew [E]dit [D]elete"
- [x] 2.3.1.7 For detail view focus: show "[E]dit [D]elete [B]ack [A]ctions"

### 2.3.2 Implement Toast Notification System

- [x] **Task 2.3.2 Complete**

Build toast notification system for displaying success/error messages that auto-dismiss.

- [x] 2.3.2.1 Add toast state: `%{message: nil, type: :success | :error, expires_at: timestamp}`
- [x] 2.3.2.2 Implement show_toast/3 function taking message, type, and duration
- [x] 2.3.2.3 When toast is active, replace shortcuts with toast message
- [x] 2.3.2.4 Apply color coding: green for success, red for error
- [x] 2.3.2.5 Add countdown timer showing "dismissed in Xs"
- [x] 2.3.2.6 Auto-dismiss toast after duration expires
- [x] 2.3.2.7 Allow manual dismiss with any key press

### 2.3.3 Unit Tests - Section 2.3

- [x] **Unit Tests 2.3 Complete**

- [x] Test StatusBar.view/1 renders shortcuts for sidebar focus
- [x] Test StatusBar.view/1 renders shortcuts for list view focus
- [x] Test StatusBar.view/1 renders shortcuts for detail view focus
- [x] Test shortcuts are context-appropriate for each view
- [x] Test show_toast/3 displays toast message
- [x] Test toast has correct color for success/error types
- [x] Test toast auto-dismisses after duration
- [x] Test toast dismisses on key press
- [x] Test toast replaces shortcuts while active

## 2.4 Sidebar Navigation Component

- [x] **Section 2.4 Complete**

The sidebar provides hierarchical navigation through domains and resources. It uses a tree-like structure with expand/collapse functionality and keyboard navigation that wraps at boundaries.

### 2.4.1 Implement Sidebar Component Structure

- [x] **Task 2.4.1 Complete**

Create the sidebar component with tree menu rendering and selection state.

- [x] 2.4.1.1 Create lib/ash_admin_tui/components/sidebar.ex module
- [x] 2.4.1.2 Define state: `%{domains: [...], selected_domain_idx: 0, selected_resource_idx: 0, expanded_domains: MapSet}`
- [x] 2.4.1.3 Implement view/1 rendering tree structure with expand/collapse indicators
- [x] 2.4.1.4 Use ▼ for expanded domains, ▶ for collapsed domains
- [x] 2.4.1.5 Use → or highlight for selected resource
- [x] 2.4.1.6 Render domain names in bold or with background color
- [x] 2.4.1.7 Apply selection highlighting with inverse video or colored background

### 2.4.2 Implement Keyboard Navigation

- [x] **Task 2.4.2 Complete**

Build keyboard navigation handling for up/down movement, expand/collapse, and selection.

- [x] 2.4.2.1 Implement event_to_msg/2 mapping arrow keys to navigation messages
- [x] 2.4.2.2 Handle Down arrow: move selection to next visible resource, wrapping at end
- [x] 2.4.2.3 Handle Up arrow: move selection to previous visible resource, wrapping at start
- [x] 2.4.2.4 Handle Right arrow: expand current domain if collapsed
- [x] 2.4.2.5 Handle Left arrow: collapse current domain if expanded
- [x] 2.4.2.6 Handle Enter: send {:select_resource, resource_name} message to parent
- [x] 2.4.2.7 Support vim-style navigation (j/k for down/up)

### 2.4.3 Implement Selection Logic

- [x] **Task 2.4.3 Complete**

Build the update/2 logic for handling navigation and selection messages.

- [x] 2.4.3.1 Implement update/2 handling {:move_selection, :down} message
- [x] 2.4.3.2 Implement update/2 handling {:move_selection, :up} message
- [x] 2.4.3.3 Implement update/2 handling {:toggle_domain, domain_name} message
- [x] 2.4.3.4 Implement selection wrapping at list boundaries
- [x] 2.4.3.5 Skip collapsed domain resources when navigating
- [x] 2.4.3.6 Return {:select_resource, resource} message to parent on Enter

### 2.4.4 Unit Tests - Section 2.4

- [x] **Unit Tests 2.4 Complete**

- [x] Test Sidebar.view/1 renders tree structure
- [x] Test expanded domains show ▼ indicator
- [x] Test collapsed domains show ▶ indicator
- [x] Test selected resource has highlight
- [x] Test Down arrow moves selection down
- [x] Test Up arrow moves selection up
- [x] Test selection wraps at list boundaries
- [x] Test Right arrow expands collapsed domain
- [x] Test Left arrow collapses expanded domain
- [x] Test Enter generates select_resource message
- [x] Test vim-style keys (j/k) work for navigation
- [x] Test collapsed domain resources are skipped

## 2.5 Content Area Router

- [x] **Section 2.5 Complete**

The content area router switches between different view types based on application state. It manages view-specific state isolation and coordinates view transitions with loading states.

### 2.5.1 Implement Content Area Component

- [x] **Task 2.5.1 Complete**

Create the content area router that renders the appropriate view based on current state.

- [x] 2.5.1.1 Create lib/ash_admin_tui/components/content_area.ex module
- [x] 2.5.1.2 Define state with view type: `:list | :detail | :form | :action | :loading | :error`
- [x] 2.5.1.3 Define view-specific state map: `%{list: %{}, detail: %{}, form: %{}, action: %{}}`
- [x] 2.5.1.4 Implement view/1 with case statement routing to view components
- [x] 2.5.1.5 Route :list to ListView.view/1
- [x] 2.5.1.6 Route :detail to DetailView.view/1
- [x] 2.5.1.7 Route :form to FormView.view/1

### 2.5.2 Implement View Transition Coordination

- [x] **Task 2.5.2 Complete**

Build view transition logic with loading states and data fetching coordination.

- [x] 2.5.2.1 Implement change_view/2 function taking target view and params
- [x] 2.5.2.2 Set view to :loading and render spinner during transitions
- [x] 2.5.2.3 Return command to fetch data for target view
- [x] 2.5.2.4 On data load complete, transition to target view with data
- [x] 2.5.2.5 On error, transition to :error view with error message
- [x] 2.5.2.6 Preserve view state when returning to previous view

### 2.5.3 Unit Tests - Section 2.5

- [x] **Unit Tests 2.5 Complete**

- [x] Test ContentArea routes :list to ListView component
- [x] Test ContentArea routes :detail to DetailView component
- [x] Test ContentArea routes :form to FormView component
- [x] Test ContentArea shows loading spinner during transitions
- [x] Test change_view/2 sets view to :loading
- [x] Test view transitions to target after data loads
- [x] Test error state displays on data fetch failure
- [x] Test previous view state is preserved on return

## 2.6 List View Component

- [ ] **Section 2.6 Complete**

The list view displays records in a table format with sorting, pagination, and row selection. It uses TermUI's Table widget and handles keyboard navigation for scrolling and selection.

### 2.6.1 Implement List View Structure

- [ ] **Task 2.6.1 Complete**

Create the list view component with table rendering and state management.

- [ ] 2.6.1.1 Create lib/ash_admin_tui/views/list_view.ex module
- [ ] 2.6.1.2 Define state: `%{resource: %{}, records: [], columns: [], selected_row: 0, sort: %{}, page: 1, total: 0}`
- [ ] 2.6.1.3 Implement init/1 to initialize with mock data (10 sample records)
- [ ] 2.6.1.4 Implement view/1 using TermUI Table widget
- [ ] 2.6.1.5 Render table header with column names
- [ ] 2.6.1.6 Render table rows with record data
- [ ] 2.6.1.7 Apply selection highlighting to selected row

### 2.6.2 Implement Table Navigation

- [ ] **Task 2.6.2 Complete**

Build keyboard navigation for table scrolling and row selection.

- [ ] 2.6.2.1 Implement event_to_msg/2 for arrow keys and page navigation
- [ ] 2.6.2.2 Handle Down arrow: increment selected_row, wrapping at end
- [ ] 2.6.2.3 Handle Up arrow: decrement selected_row, wrapping at start
- [ ] 2.6.2.4 Handle PgDown: advance by page_size rows
- [ ] 2.6.2.5 Handle PgUp: go back by page_size rows
- [ ] 2.6.2.6 Handle Home: jump to first row
- [ ] 2.6.2.7 Handle End: jump to last row
- [ ] 2.6.2.8 Handle Enter: generate {:view_detail, record_id} message

### 2.6.3 Implement Action Shortcuts

- [ ] **Task 2.6.3 Complete**

Add keyboard shortcuts for common actions (new, edit, delete).

- [ ] 2.6.3.1 Handle 'n' key: generate {:new_record} message
- [ ] 2.6.3.2 Handle 'e' key: generate {:edit_record, selected_id} message
- [ ] 2.6.3.3 Handle 'd' key: generate {:delete_record, selected_id} message
- [ ] 2.6.3.4 Handle 'a' key: generate {:show_actions, selected_id} message
- [ ] 2.6.3.5 Add footer showing available actions
- [ ] 2.6.3.6 Display pagination info: "Page X of Y | Z records"

### 2.6.4 Unit Tests - Section 2.6

- [ ] **Unit Tests 2.6 Complete**

- [ ] Test ListView.init/1 creates initial state with mock data
- [ ] Test ListView.view/1 renders table with headers
- [ ] Test table displays all records
- [ ] Test selected row has highlighting
- [ ] Test Down arrow moves selection down
- [ ] Test Up arrow moves selection up
- [ ] Test selection wraps at boundaries
- [ ] Test PgDown/PgUp navigate by page
- [ ] Test Home/End jump to first/last
- [ ] Test Enter generates view_detail message
- [ ] Test 'n' generates new_record message
- [ ] Test 'e' generates edit_record message
- [ ] Test 'd' generates delete_record message

## 2.7 Detail View Component

- [ ] **Section 2.7 Complete**

The detail view displays all attributes of a single record in a readable two-column format. It supports navigation to related records and provides action shortcuts.

### 2.7.1 Implement Detail View Structure

- [ ] **Task 2.7.1 Complete**

Create the detail view component with field display and relationship rendering.

- [ ] 2.7.1.1 Create lib/ash_admin_tui/views/detail_view.ex module
- [ ] 2.7.1.2 Define state: `%{resource: %{}, record: %{}, relationships: %{}, selected_field_idx: 0}`
- [ ] 2.7.1.3 Implement init/2 taking resource and record ID, load mock record
- [ ] 2.7.1.4 Implement view/1 with title showing resource name and ID
- [ ] 2.7.1.5 Render attributes section with two-column layout (field name | value)
- [ ] 2.7.1.6 Render relationships section below attributes
- [ ] 2.7.1.7 Add footer with action shortcuts

### 2.7.2 Implement Field Formatting

- [ ] **Task 2.7.2 Complete**

Build field formatting functions for different attribute types.

- [ ] 2.7.2.1 Create format_field/2 function taking field type and value
- [ ] 2.7.2.2 Format strings: display as-is with wrapping for long text
- [ ] 2.7.2.3 Format numbers: right-align with thousand separators
- [ ] 2.7.2.4 Format dates: "YYYY-MM-DD" format
- [ ] 2.7.2.5 Format datetimes: "YYYY-MM-DD HH:MM:SS UTC" format
- [ ] 2.7.2.6 Format booleans: "Yes"/"No" with green/red color
- [ ] 2.7.2.7 Format relationships: show related record identifier with → indicator

### 2.7.3 Implement Navigation and Actions

- [ ] **Task 2.7.3 Complete**

Add keyboard navigation for relationships and action shortcuts.

- [ ] 2.7.3.1 Handle Up/Down arrows: navigate through fields and relationships
- [ ] 2.7.3.2 Handle Enter on relationship: generate {:navigate_to_related, resource, id} message
- [ ] 2.7.3.3 Handle 'e' key: generate {:edit_record, id} message
- [ ] 2.7.3.4 Handle 'd' key: generate {:delete_record, id} message
- [ ] 2.7.3.5 Handle 'b' or Esc: generate {:back_to_list} message
- [ ] 2.7.3.6 Handle 'a' key: generate {:show_actions} message

### 2.7.4 Unit Tests - Section 2.7

- [ ] **Unit Tests 2.7 Complete**

- [ ] Test DetailView.init/2 loads mock record data
- [ ] Test DetailView.view/1 renders title with resource name and ID
- [ ] Test attributes section displays all fields
- [ ] Test fields use two-column layout
- [ ] Test format_field/2 correctly formats strings
- [ ] Test format_field/2 correctly formats numbers
- [ ] Test format_field/2 correctly formats dates
- [ ] Test format_field/2 correctly formats booleans with color
- [ ] Test relationships section displays related records
- [ ] Test Up/Down arrows navigate fields
- [ ] Test Enter on relationship generates navigate message
- [ ] Test 'e' generates edit message
- [ ] Test 'd' generates delete message
- [ ] Test 'b' generates back_to_list message

## 2.8 Form View Component

- [ ] **Section 2.8 Complete**

The form view provides create and edit forms with field validation and relationship selection. It dynamically generates form fields based on resource attributes and uses PickList for associations.

### 2.8.1 Implement Form View Structure

- [ ] **Task 2.8.1 Complete**

Create the form view component with field rendering and validation display.

- [ ] 2.8.1.1 Create lib/ash_admin_tui/views/form_view.ex module
- [ ] 2.8.1.2 Define state: `%{resource: %{}, mode: :create | :edit, record_id: nil, form_values: %{}, errors: %{}, focused_field: nil}`
- [ ] 2.8.1.3 Implement init/2 for create mode with empty form values
- [ ] 2.8.1.4 Implement init/3 for edit mode with pre-populated values
- [ ] 2.8.1.5 Implement view/1 with title "Create <Resource>" or "Edit <Resource>"
- [ ] 2.8.1.6 Render form fields with labels and input widgets
- [ ] 2.8.1.7 Display validation errors below fields in red

### 2.8.2 Implement Field Input Widgets

- [ ] **Task 2.8.2 Complete**

Build input widgets for different field types with appropriate validation.

- [ ] 2.8.2.1 Create render_field/3 function taking field type, value, and focus
- [ ] 2.8.2.2 For string fields: render TextInput widget
- [ ] 2.8.2.3 For number fields: render TextInput with numeric validation
- [ ] 2.8.2.4 For boolean fields: render checkbox or toggle
- [ ] 2.8.2.5 For enum fields: render select/dropdown with allowed values
- [ ] 2.8.2.6 For association fields: render PickList trigger with search
- [ ] 2.8.2.7 Apply focus styling to currently focused field

### 2.8.3 Implement Form Navigation and Submission

- [ ] **Task 2.8.3 Complete**

Add keyboard navigation between fields and form submission handling.

- [ ] 2.8.3.1 Handle Tab: move focus to next field
- [ ] 2.8.3.2 Handle Shift-Tab: move focus to previous field
- [ ] 2.8.3.3 Handle F5 or Ctrl-S: validate and submit form
- [ ] 2.8.3.4 Handle Esc: show confirmation dialog if changes made, else go back
- [ ] 2.8.3.5 Implement client-side validation on field blur
- [ ] 2.8.3.6 Generate {:submit_form, mode, values} message on submit
- [ ] 2.8.3.7 Display validation errors and focus first error field

### 2.8.4 Unit Tests - Section 2.8

- [ ] **Unit Tests 2.8 Complete**

- [ ] Test FormView.init/2 creates empty form for create mode
- [ ] Test FormView.init/3 pre-populates form for edit mode
- [ ] Test FormView.view/1 renders title correctly
- [ ] Test form displays all fields with labels
- [ ] Test render_field/3 creates TextInput for string fields
- [ ] Test render_field/3 creates numeric input for number fields
- [ ] Test render_field/3 creates checkbox for boolean fields
- [ ] Test Tab moves focus to next field
- [ ] Test Shift-Tab moves focus to previous field
- [ ] Test F5 submits form with validation
- [ ] Test validation errors display below fields
- [ ] Test Esc shows confirmation if changes made
- [ ] Test submit generates correct message

## 2.9 Integration Tests

- [ ] **Section 2.9 Complete**

Integration tests validate the complete navigation flow and interaction between all Phase 2 components.

### 2.9.1 Complete Navigation Flow

- [ ] **Task 2.9.1 Complete**

Test full navigation from sidebar selection through list view to detail view.

- [ ] Test sidebar displays domains and resources
- [ ] Test selecting a resource in sidebar loads list view
- [ ] Test list view displays mock records in table
- [ ] Test selecting a row in list view loads detail view
- [ ] Test detail view displays record details
- [ ] Test pressing 'b' in detail view returns to list view
- [ ] Test focus management works throughout navigation

### 2.9.2 Form Workflow

- [ ] **Task 2.9.2 Complete**

Validate create and edit form workflows from list and detail views.

- [ ] Test pressing 'n' in list view opens create form
- [ ] Test create form displays empty fields
- [ ] Test filling form and submitting generates submit message
- [ ] Test pressing 'e' in detail view opens edit form
- [ ] Test edit form pre-populates with current values
- [ ] Test form validation displays errors
- [ ] Test Esc cancels form and returns to previous view

### 2.9.3 Keyboard Navigation

- [ ] **Task 2.9.3 Complete**

Verify all keyboard shortcuts work correctly across all views.

- [ ] Test arrow keys navigate sidebar
- [ ] Test Enter selects resource in sidebar
- [ ] Test arrow keys navigate list view table
- [ ] Test PgUp/PgDown work in list view
- [ ] Test action shortcuts (n/e/d/a) work in list view
- [ ] Test arrow keys navigate detail view fields
- [ ] Test Tab/Shift-Tab navigate form fields
- [ ] Test global shortcuts (Q for quit) work everywhere

### 2.9.4 Layout and Focus

- [ ] **Task 2.9.4 Complete**

Ensure layout management and focus system work correctly.

- [ ] Test Tab key switches focus between sidebar and content
- [ ] Test focused component has visual highlight
- [ ] Test keyboard events route to focused component
- [ ] Test status bar updates based on current focus/view
- [ ] Test top bar breadcrumb updates with navigation
- [ ] Test layout adapts to terminal resize

## Phase 2 Success Criteria

Phase 2 is complete when all of the following criteria are met:

1. **Navigation Works**: Users can browse domains and resources using keyboard in sidebar
2. **Views Render**: List, detail, and form views display correctly with mock data
3. **Interaction Complete**: All keyboard shortcuts work for navigation and actions
4. **Focus Management**: Tab key switches focus, visual feedback shows active component
5. **Context Display**: Top bar shows navigation breadcrumb, status bar shows shortcuts
6. **Tests Pass**: All unit and integration tests pass
7. **No Real Data**: Phase 2 uses only mock data; Ash integration is Phase 3

## Provides Foundation For

Phase 2 creates the UI foundation for:

- **Phase 3**: Authentication and Ash integration (replace mock data with real queries)
- **Phase 4**: Advanced features (actor switching, multi-tenancy, custom actions)

The component architecture and navigation system will support real data operations without requiring structural changes.
