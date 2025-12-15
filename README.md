# AshAdmin TUI

A cross-platform Terminal User Interface (TUI) for AshAdmin, bringing the full power of Ash Framework's admin interface to your terminal.

## Overview

AshAdmin TUI provides a complete terminal-based admin interface for Ash Framework applications, replicating all functionality of the web-based AshAdmin with a rich, keyboard-driven interface. Built with TermUI, it offers a familiar admin experience optimized for terminal environments, perfect for remote administration, SSH sessions, and developers who prefer working in the terminal.

## Why AshAdmin TUI?

While AshAdmin's Phoenix LiveView interface is excellent for web-based administration, there are scenarios where a terminal interface is preferable:

- **Remote Administration**: Manage your Ash applications over SSH without X forwarding or web access
- **Resource Efficiency**: Lighter weight than running a full web browser
- **Terminal Workflows**: Integrate admin tasks seamlessly into terminal-based development workflows
- **Accessibility**: Provide admin access in environments where web interfaces are restricted
- **Developer Preference**: For those who live in the terminal and prefer keyboard-driven interfaces

## Project Status

⚠️ **Early Development** - This project is currently in the research and planning phase. Implementation has not yet begun.

Current phase:
- ✅ Research completed (see `notes/research/designing-a-tui-for-ash-admin.md`)
- 🔄 Architecture planning in progress
- ⏳ Implementation not started

## Planned Features

### Complete AshAdmin Functionality

- **Resource Management**
  - List views with pagination, sorting, and filtering
  - Detail views for individual records
  - Create/edit forms with validation
  - Delete operations with confirmation prompts
  - Custom action execution

- **Navigation & Discovery**
  - Domain-based resource organization
  - Hierarchical menu navigation
  - Keyboard shortcuts for common operations
  - Context-sensitive help

- **Authentication & Authorization**
  - AshAuthentication integration
  - Role-based access control
  - Actor switching (impersonation)
  - Multi-tenancy support

- **Cross-Platform**
  - Linux support
  - macOS support
  - Windows 10+ support

### User Experience

- **Intuitive Navigation**: Familiar keyboard shortcuts (vim-style, arrow keys, etc.)
- **Visual Feedback**: Clear selection highlighting, status messages, progress indicators
- **Responsive Layout**: Adapts to different terminal sizes
- **Rich Widgets**: Tables, forms, dialogs, menus, and more via TermUI
- **Error Handling**: Clear error messages and validation feedback

## Technology Stack

- **Language**: Elixir
- **UI Framework**: [TermUI](https://github.com/pcharbon70/term_ui) - Elm-style architecture for terminal UIs
- **Backend Integration**: [Ash Framework](https://ash-hq.org/) - Data layer integration
- **Authentication**: [AshAuthentication](https://hexdocs.pm/ash_authentication) - Secure admin access
- **Testing**: ExUnit with comprehensive test coverage

## Architecture

### Design Principles

1. **Configuration Reuse**: Leverages existing AshAdmin.Domain and AshAdmin.Resource DSL configurations
2. **Feature Parity**: Maintains 1:1 feature parity with web-based AshAdmin
3. **Framework Integration**: Uses Ash's introspection and action system directly
4. **Cross-Platform**: Built on TermUI's cross-platform terminal abstraction

### Key Components

```
┌─────────────────────────────────────────┐
│         Top Bar (Context Info)          │
├──────────────┬──────────────────────────┤
│              │                          │
│   Resource   │     Main Content Area    │
│   Menu       │  (List/Detail/Form/etc)  │
│  (Domains)   │                          │
│              │                          │
├──────────────┴──────────────────────────┤
│    Status Bar (Help & Shortcuts)        │
└─────────────────────────────────────────┘
```

### Interface Layout

- **Top Bar**: Current actor, tenant, and application context
- **Left Pane**: Domain and resource navigation menu
- **Right Pane**: Active view (list, detail, form, or action dialog)
- **Bottom Bar**: Keyboard shortcuts and status messages

## Planned Installation

**Note**: Not yet implemented

```elixir
# Add to mix.exs dependencies
def deps do
  [
    {:ash_admin_tui, "~> 0.1.0"}
  ]
end
```

## Planned Usage

**Note**: Not yet implemented

```bash
# Start the TUI
mix ash_admin.tui

# Or as an escript
./ash_admin_tui
```

## Configuration

The TUI will automatically use your existing AshAdmin configuration:

```elixir
# Existing AshAdmin configuration works automatically
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    extensions: [AshAdmin.Resource]

  admin do
    actor? true  # TUI will respect this for impersonation
  end

  # ... resource definition
end

defmodule MyApp.Accounts do
  use Ash.Domain,
    extensions: [AshAdmin.Domain]

  admin do
    show? true  # TUI will include this domain
  end

  # ... domain definition
end
```

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- Terminal with UTF-8 support

### Getting Started

```bash
# Clone the repository
git clone https://github.com/yourusername/ash_admin_tui.git
cd ash_admin_tui

# Install dependencies
mix deps.get

# Run tests (when available)
mix test

# Start development
mix run --no-halt
```

## Roadmap

### Phase 1: Foundation (Planned)
- [ ] Project structure setup
- [ ] TermUI integration
- [ ] Basic navigation framework
- [ ] Resource introspection

### Phase 2: Core Features (Planned)
- [ ] List views with tables
- [ ] Detail views
- [ ] Create/edit forms
- [ ] Delete operations
- [ ] Authentication integration

### Phase 3: Advanced Features (Planned)
- [ ] Custom actions
- [ ] Actor switching
- [ ] Multi-tenancy support
- [ ] Advanced filtering and sorting

### Phase 4: Polish (Planned)
- [ ] Help system
- [ ] Configuration options
- [ ] Performance optimization
- [ ] Documentation

## Documentation

- [Design Document](notes/research/designing-a-tui-for-ash-admin.md) - Comprehensive TUI design and architecture
- [CLAUDE.md](CLAUDE.md) - Development guidelines and agent system

## Contributing

Contributions are welcome once the initial implementation is complete. Please check back for contribution guidelines.

## Relationship to AshAdmin

This project is a complementary interface to [AshAdmin](https://github.com/ash-project/ash_admin), not a replacement. It aims to:

- Reuse the same configuration (AshAdmin.Domain and AshAdmin.Resource DSLs)
- Maintain feature parity with the web interface
- Provide an alternative interface optimized for terminal use
- Honor the same authentication and authorization mechanisms

## License

TBD

## Acknowledgments

- [Ash Framework](https://ash-hq.org/) - The incredible data layer framework
- [AshAdmin](https://github.com/ash-project/ash_admin) - The web admin interface this project complements
- [TermUI](https://github.com/pcharbon70/term_ui) - The terminal UI framework powering the interface
- The Elixir community for their continuous support and innovation

---

**Status**: 🚧 Early Development - Not yet functional

For questions or discussions, please open an issue on GitHub.
