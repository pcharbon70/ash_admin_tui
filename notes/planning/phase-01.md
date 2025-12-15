# Phase 1: Foundation - Project Setup and Architecture

## Phase Overview

Phase 1 establishes the foundational infrastructure for ash_admin_tui, transforming the project from its current state (documentation only) into a functional Elixir application with TermUI integration. This phase creates the OTP application structure, establishes the supervision tree, and implements a basic TermUI interface that can be launched via Mix task.

The foundation provides three critical layers: OTP application management for process supervision, TermUI integration following the Elm Architecture pattern, and development infrastructure including configuration, testing, and code quality tools. By the end of this phase, developers will have a runnable TUI application displaying a welcome screen with basic keyboard interaction.

This phase is intentionally minimal to establish a working baseline quickly. Subsequent phases will build upon this foundation to add resource discovery, navigation, CRUD operations, and authentication.

## 1.1 Mix Project Initialization

- [ ] **Section 1.1 Complete**

The Mix project structure provides the scaffolding for all subsequent development. Creating a well-organized directory structure from the start prevents technical debt and establishes conventions that guide implementation. The project metadata in mix.exs defines dependencies, Elixir version requirements, and build configuration that will be used throughout development.

### 1.1.1 Create Mix Project Structure

- [x] **Task 1.1.1 Complete**

Initialize the Elixir Mix project with appropriate metadata and directory structure. The project uses standard Mix conventions for lib/, test/, and config/ directories, with additional organization for UI components and future Ash integration logic.

- [x] 1.1.1.1 Run `mix new ash_admin_tui --sup` to create supervised application structure
- [x] 1.1.1.2 Update mix.exs metadata (description, version 0.1.0, authors, licenses)
- [x] 1.1.1.3 Create lib/ash_admin_tui/ui/ directory for TermUI components
- [x] 1.1.1.4 Create lib/ash_admin_tui/core/ directory for future Ash integration
- [x] 1.1.1.5 Create lib/mix/tasks/ directory for custom Mix tasks
- [x] 1.1.1.6 Add .gitignore entries for build artifacts and editor files
- [x] 1.1.1.7 Create README.md with project description and setup instructions

### 1.1.2 Unit Tests - Section 1.1

- [ ] **Unit Tests 1.1 Complete**

- [ ] Test mix.exs compiles without errors
- [ ] Test application module exists and loads
- [ ] Test directory structure matches expected layout
- [ ] Test .gitignore includes all necessary exclusions

## 1.2 Dependency Management

- [ ] **Section 1.2 Complete**

Proper dependency management ensures the project has access to all required libraries with compatible versions. TermUI provides the UI framework, Ash and AshAdmin enable resource integration, and development tools maintain code quality. Version constraints prevent breaking changes from upstream dependencies.

### 1.2.1 Add Core Dependencies

- [ ] **Task 1.2.1 Complete**

Configure mix.exs with production dependencies needed for the TUI functionality. TermUI is the primary UI framework, while Ash ecosystem packages enable admin functionality.

- [ ] 1.2.1.1 Add `{:term_ui, "~> 0.2.0"}` to deps for terminal UI framework
- [ ] 1.2.1.2 Add `{:ash, "~> 3.0"}` to deps for Ash framework integration
- [ ] 1.2.1.3 Add `{:ash_admin, "~> 0.11"}` to deps for AshAdmin DSL configuration reuse
- [ ] 1.2.1.4 Add `{:jason, "~> 1.4"}` to deps for JSON encoding/decoding
- [ ] 1.2.1.5 Run `mix deps.get` to fetch dependencies
- [ ] 1.2.1.6 Run `mix deps.compile` to compile dependencies

### 1.2.2 Add Development Dependencies

- [ ] **Task 1.2.2 Complete**

Configure development and test dependencies per CLAUDE.md standards. These tools enforce code quality and enable comprehensive testing.

- [ ] 1.2.2.1 Add `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` for code analysis
- [ ] 1.2.2.2 Add `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}` for type checking
- [ ] 1.2.2.3 Add `{:ex_doc, "~> 0.31", only: :dev, runtime: false}` for documentation
- [ ] 1.2.2.4 Add `{:mimic, "~> 1.7", only: :test}` for test mocking (per CLAUDE.md: use expect not stub)
- [ ] 1.2.2.5 Add `{:excoveralls, "~> 0.18", only: :test}` for test coverage reporting
- [ ] 1.2.2.6 Run `mix deps.get` to fetch development dependencies

### 1.2.3 Unit Tests - Section 1.2

- [ ] **Unit Tests 1.2 Complete**

- [ ] Test all dependencies resolve without conflicts
- [ ] Test mix compile succeeds with all dependencies
- [ ] Test TermUI is available and can be referenced
- [ ] Test Ash and AshAdmin modules are accessible
- [ ] Test development tools (Credo, Dialyzer) are available in dev environment

## 1.3 OTP Application Structure

- [ ] **Section 1.3 Complete**

The OTP application structure provides process supervision and lifecycle management for the TUI. The supervision tree ensures the TermUI runtime process is monitored and restarted on failure. Wrapping TermUI.Runtime in a GenServer allows integration with OTP supervision while maintaining the Elm Architecture pattern.

### 1.3.1 Implement Application Module

- [ ] **Task 1.3.1 Complete**

Create the OTP application entry point that defines the supervision tree. This module is called when the application starts and establishes the top-level supervisor.

- [ ] 1.3.1.1 Implement `AshAdminTui.Application.start/2` callback
- [ ] 1.3.1.2 Define supervision tree with `:one_for_one` strategy
- [ ] 1.3.1.3 Add `AshAdminTui.UI.Runtime` as supervised child with `:permanent` restart
- [ ] 1.3.1.4 Configure application in mix.exs with `mod: {AshAdminTui.Application, []}`
- [ ] 1.3.1.5 Add application description and extra_applications (logger)

### 1.3.2 Create TermUI Runtime Wrapper

- [ ] **Task 1.3.2 Complete**

Build a GenServer that wraps TermUI.Runtime, providing OTP supervision integration and lifecycle management. This wrapper handles startup, shutdown, and crash recovery.

- [ ] 1.3.2.1 Create lib/ash_admin_tui/ui/runtime.ex module
- [ ] 1.3.2.2 Implement GenServer with `use GenServer` and standard callbacks
- [ ] 1.3.2.3 In init/1, start TermUI.Runtime with root component reference
- [ ] 1.3.2.4 Implement handle_info callbacks for TermUI messages
- [ ] 1.3.2.5 Implement terminate/2 for graceful TermUI shutdown
- [ ] 1.3.2.6 Add child_spec with unique :id and restart strategy

### 1.3.3 Unit Tests - Section 1.3

- [ ] **Unit Tests 1.3 Complete**

- [ ] Test Application.start/2 returns supervision tree
- [ ] Test supervision tree includes Runtime as child
- [ ] Test Runtime GenServer starts successfully
- [ ] Test Runtime GenServer is supervised with :permanent restart
- [ ] Test Runtime GenServer terminates gracefully on shutdown
- [ ] Test Runtime GenServer restarts on crash

## 1.4 TermUI Integration

- [ ] **Section 1.4 Complete**

TermUI integration implements the Elm Architecture pattern with init, update, and view functions. The root component maintains application state and renders the initial UI layout. This phase creates a minimal but functional interface to validate the TermUI integration before adding complex features.

### 1.4.1 Implement Root Component

- [ ] **Task 1.4.1 Complete**

Create the root TermUI component following the Elm Architecture. This component serves as the entry point for all UI rendering and state management.

- [ ] 1.4.1.1 Create lib/ash_admin_tui/ui/root.ex module
- [ ] 1.4.1.2 Define state structure: `%{view: :welcome, quit_requested: false}`
- [ ] 1.4.1.3 Implement init/1 function returning initial state and empty command list
- [ ] 1.4.1.4 Implement event_to_msg/2 for keyboard events (map 'q' to :quit message)
- [ ] 1.4.1.5 Implement update/2 handling :quit message (sets quit_requested: true, returns :stop command)
- [ ] 1.4.1.6 Implement view/1 rendering welcome screen with title and instructions

### 1.4.2 Create Initial Layout

- [ ] **Task 1.4.2 Complete**

Build the basic three-section layout (top bar, content area, status bar) using TermUI widgets. This establishes the visual structure that will be enhanced in later phases.

- [ ] 1.4.2.1 In view/1, create vertical stack layout with three sections
- [ ] 1.4.2.2 Implement top bar section (height: 2 lines) with application title "AshAdmin TUI"
- [ ] 1.4.2.3 Implement content area section (fills remaining space) with welcome message
- [ ] 1.4.2.4 Implement status bar section (height: 1 line) with "[Q] Quit" shortcut hint
- [ ] 1.4.2.5 Add border styling using TermUI box-drawing characters
- [ ] 1.4.2.6 Apply color scheme (default terminal colors for MVP)

### 1.4.3 Unit Tests - Section 1.4

- [ ] **Unit Tests 1.4 Complete**

- [ ] Test Root.init/1 returns valid initial state
- [ ] Test Root.event_to_msg/2 maps 'q' key to :quit message
- [ ] Test Root.update/2 handles :quit message and returns :stop command
- [ ] Test Root.view/1 renders without errors
- [ ] Test Root.view/1 output contains "AshAdmin TUI" title
- [ ] Test Root.view/1 output contains "[Q] Quit" hint

## 1.5 Configuration System

- [ ] **Section 1.5 Complete**

The configuration system allows customization of TUI behavior through config files and environment variables. This includes API endpoints, UI preferences, logging levels, and session management. Configuration validation prevents runtime errors from invalid settings.

### 1.5.1 Implement Configuration Module

- [ ] **Task 1.5.1 Complete**

Create a configuration management module that reads, validates, and provides access to application settings.

- [ ] 1.5.1.1 Create lib/ash_admin_tui/config.ex module
- [ ] 1.5.1.2 Implement get/2 function to retrieve config values with defaults
- [ ] 1.5.1.3 Implement validate/0 function to check required config values
- [ ] 1.5.1.4 Add support for environment variable overrides (ASH_ADMIN_* prefix)
- [ ] 1.5.1.5 Create helper functions for common config: api_url/0, log_level/0, theme/0

### 1.5.2 Create Configuration Files

- [ ] **Task 1.5.2 Complete**

Define configuration files for different environments (dev, test, prod) following Elixir conventions.

- [ ] 1.5.2.1 Create config/config.exs with default settings
- [ ] 1.5.2.2 Configure logger with level :info, format options, and metadata
- [ ] 1.5.2.3 Create config/dev.exs with development overrides
- [ ] 1.5.2.4 Create config/test.exs with test environment settings (logger level :warning)
- [ ] 1.5.2.5 Create config/runtime.exs for runtime configuration (API URL from env vars)
- [ ] 1.5.2.6 Add config imports to config.exs for environment-specific files

### 1.5.3 Unit Tests - Section 1.5

- [ ] **Unit Tests 1.5 Complete**

- [ ] Test Config.get/2 retrieves configured values
- [ ] Test Config.get/2 returns default when key missing
- [ ] Test Config.validate/0 succeeds with valid configuration
- [ ] Test environment variable overrides work correctly
- [ ] Test helper functions (api_url/0, log_level/0) return expected values

## 1.6 Development Workflow

- [ ] **Section 1.6 Complete**

Development workflow tools streamline daily development tasks. The Mix task provides the primary user entry point for launching the TUI. Code quality tools (Credo, Dialyzer) maintain standards, and testing infrastructure ensures reliability.

### 1.6.1 Create Mix Task for TUI Launch

- [ ] **Task 1.6.1 Complete**

Implement a custom Mix task that starts the TUI application. This provides a convenient command-line interface for users and developers.

- [ ] 1.6.1.1 Create lib/mix/tasks/ash_admin.tui.ex module
- [ ] 1.6.1.2 Define module `Mix.Tasks.AshAdmin.Tui` with `use Mix.Task`
- [ ] 1.6.1.3 Add @shortdoc "Launch AshAdmin TUI"
- [ ] 1.6.1.4 Implement run/1 function that starts the application
- [ ] 1.6.1.5 Call `Mix.Task.run("app.start")` to ensure application is running
- [ ] 1.6.1.6 Add infinite sleep or signal handling to keep task alive
- [ ] 1.6.1.7 Handle Ctrl-C gracefully for clean shutdown

### 1.6.2 Configure Code Quality Tools

- [ ] **Task 1.6.2 Complete**

Set up Credo and Dialyzer with project-specific configurations per CLAUDE.md standards.

- [ ] 1.6.2.1 Create .credo.exs with strict configuration
- [ ] 1.6.2.2 Enable all Credo checks except design-related (to be enabled incrementally)
- [ ] 1.6.2.3 Run `mix credo --strict` to verify configuration
- [ ] 1.6.2.4 Create dialyzer.ignore-warnings file for known false positives
- [ ] 1.6.2.5 Run `mix dialyzer` to generate initial PLT
- [ ] 1.6.2.6 Configure Dialyzer in mix.exs with appropriate flags

### 1.6.3 Set Up Testing Infrastructure

- [ ] **Task 1.6.3 Complete**

Configure ExUnit testing framework with coverage reporting and Mimic for mocking.

- [ ] 1.6.3.1 Update test/test_helper.exs to start ExUnit with coverage enabled
- [ ] 1.6.3.2 Configure ExCoveralls in mix.exs with coverage goals (80% minimum)
- [ ] 1.6.3.3 Add Mimic.copy/1 to test_helper.exs for modules to be mocked
- [ ] 1.6.3.4 Create test/ash_admin_tui/ui/root_test.exs for root component tests
- [ ] 1.6.3.5 Create test/ash_admin_tui/config_test.exs for configuration tests
- [ ] 1.6.3.6 Run `mix test` to verify test suite passes

### 1.6.4 Unit Tests - Section 1.6

- [ ] **Unit Tests 1.6 Complete**

- [ ] Test Mix task exists and is discoverable via `mix help`
- [ ] Test Mix task starts application successfully
- [ ] Test Credo runs without errors
- [ ] Test Dialyzer runs without warnings (after initial PLT build)
- [ ] Test coverage reporting generates reports
- [ ] Test all unit tests pass with 80%+ coverage

## 1.7 Integration Tests

- [ ] **Section 1.7 Complete**

Integration tests validate that all Phase 1 components work together correctly. These tests ensure the complete system behaves as expected from end-to-end.

### 1.7.1 Application Startup

- [ ] **Task 1.7.1 Complete**

Test that the application starts successfully and all supervised processes initialize correctly.

- [ ] Test application starts with `Application.start(:ash_admin_tui)`
- [ ] Test supervision tree is established with Runtime GenServer
- [ ] Test Runtime GenServer is running after application start
- [ ] Test application stops cleanly with `Application.stop(:ash_admin_tui)`

### 1.7.2 TermUI Rendering

- [ ] **Task 1.7.2 Complete**

Validate that the TermUI interface renders correctly and displays the expected content.

- [ ] Test Root component initializes with correct state
- [ ] Test view/1 generates valid TermUI render tree
- [ ] Test welcome screen contains "AshAdmin TUI" title
- [ ] Test status bar contains "[Q] Quit" hint
- [ ] Test layout has three sections (top bar, content, status bar)

### 1.7.3 Event Handling

- [ ] **Task 1.7.3 Complete**

Verify that keyboard events are correctly processed and result in appropriate state changes.

- [ ] Test pressing 'q' key generates :quit message
- [ ] Test :quit message sets quit_requested to true
- [ ] Test :quit message returns :stop command
- [ ] Test application shuts down in response to :stop command

### 1.7.4 Configuration Integration

- [ ] **Task 1.7.4 Complete**

Ensure configuration is loaded correctly and accessible throughout the application.

- [ ] Test config values are loaded from config files
- [ ] Test environment variables override config file values
- [ ] Test Config module accessible from all application modules
- [ ] Test invalid configuration triggers validation errors

## Phase 1 Success Criteria

The foundation phase is complete when all of the following criteria are met:

1. **Application Launches**: Running `mix ash_admin.tui` starts the TUI application
2. **UI Renders**: Terminal displays the welcome screen with proper layout (top bar, content, status bar)
3. **Interaction Works**: Pressing 'q' quits the application gracefully
4. **Tests Pass**: All unit and integration tests pass with 80%+ coverage
5. **Quality Checks**: Credo and Dialyzer report no issues
6. **Documentation**: README.md contains setup and usage instructions
7. **Configuration**: Config system loads and validates settings correctly

## Provides Foundation For

Phase 1 establishes the foundation for subsequent phases:

- **Phase 2**: Core UI components (sidebar navigation, content area router, list/detail/form views)
- **Phase 3**: Authentication integration and Ash resource operations
- **Phase 4**: Advanced features (actor switching, multi-tenancy, custom actions)

The supervision tree, TermUI integration, and development infrastructure created in Phase 1 will support all future features without requiring architectural changes.
