# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ash_admin_tui** is a Terminal User Interface (TUI) for AshAdmin, providing full admin functionality for Ash Framework applications through a terminal-based interface. The project replicates all features of the web-based AshAdmin using TermUI for cross-platform terminal UI rendering.

## Project Status

This is an early-stage project currently in the research and planning phase. No implementation code exists yet - only research documentation and agent/command configurations.

## Technology Stack (Planned)

- **Language**: Elixir
- **UI Framework**: TermUI (Elm-style architecture for terminal UIs)
- **Backend Framework**: Ash Framework (will integrate with existing Ash applications)
- **Authentication**: AshAuthentication (for admin access control)
- **Target**: Cross-platform terminal interface (Linux, macOS, Windows 10+)

## Architecture Philosophy

### Key Design Principles

1. **Configuration Reuse**: Leverage existing AshAdmin DSL and resource configurations
2. **Feature Parity**: Replicate all web UI functionality in terminal form
3. **Pattern Discovery**: Always discover and follow existing project patterns rather than inventing new ones
4. **Project-First Approach**: Use libraries already in the project; flag new dependencies for approval

### Four-Phase Workflow

Complex features follow a structured workflow:

1. **Research** (`/research`) - Codebase impact analysis with third-party integration detection
2. **Plan** (`/plan`) - Strategic implementation planning using discovered patterns
3. **Breakdown** (`/breakdown`) - Numbered task checklists with detailed steps
4. **Execute** (`/execute`) - Sequential implementation following breakdown

## Specialized Agents

This project uses a comprehensive agent system for coordination and quality assurance:

### Core Development Agents

- **elixir-expert** - MANDATORY for all Elixir/Phoenix/Ecto/Ash work (uses `usage_rules.md`)
- **research-agent** - MANDATORY for technical research and documentation
- **architecture-agent** - Code placement, module organization, integration patterns
- **implementation-agent** - Plan execution with agent coordination

### Planning Agents

- **feature-planner** - Comprehensive feature planning (complex features)
- **fix-planner** - Focused bug fix planning
- **task-planner** - Lightweight task planning

### Quality Assurance (Run in Parallel)

ALL review agents MUST run in parallel after implementation:

- **elixir-reviewer** - Code quality, Credo, Dialyzer, Sobelow, security scanning
- **factual-reviewer** - Implementation vs planning verification
- **qa-reviewer** - Test coverage, edge cases, quality assurance
- **senior-engineer-reviewer** - Scalability, technical debt, strategic decisions
- **security-reviewer** - OWASP Top 10, vulnerabilities, threat modeling
- **consistency-reviewer** - Pattern consistency, naming, style guidelines
- **redundancy-reviewer** - Code duplication, refactoring opportunities

### Documentation Specialists

- **documentation-expert** - MANDATORY for creating/updating documentation
- **documentation-reviewer** - Documentation quality assurance

### Testing Specialists

- **test-developer** - Systematic test development methodology
- **test-fixer** - Test failure diagnosis and resolution

## Elixir Development Standards

### CRITICAL: Ash Framework Migrations

```elixir
# ✅ CORRECT - Always use ash.codegen for Ash resources
mix ash.codegen initial_migration
mix ash.codegen add_users

# ❌ INCORRECT - Never use ecto.gen.migration for Ash resources
mix ecto.gen.migration add_users  # Wrong!
```

### Running Elixir Scripts

```elixir
# ✅ CORRECT - Use mix run for project scripts
mix run my_script.exs
MIX_ENV=prod mix run priv/repo/seeds.exs

# ❌ INCORRECT - Don't use elixir command in Mix projects
elixir my_script.exs  # Wrong!
```

### Pipe Operator Usage

```elixir
# ✅ Single operation - No pipe
Enum.map(list, & &1 * 2)

# ✅ Multiple operations - Use pipe chain
list
|> Enum.map(& &1 * 2)
|> Enum.filter(& rem(&1, 2) == 0)
|> Enum.sum()

# ❌ Don't use pipe for single operation
list |> Enum.map(& &1 * 2)
```

### LiveView Components

Always create public wrapper functions with `attr` declarations:

```elixir
defmodule MyAppWeb.Components.UserCard do
  use MyAppWeb, :live_component

  attr :user, :map, required: true
  attr :show_email, :boolean, default: false

  def user_card(assigns) do
    ~H"""
    <.live_component
      module={__MODULE__}
      id={"user-card-#{@user.id}"}
      user={@user}
      show_email={@show_email}
    />
    """
  end

  def render(assigns) do
    ~H"""
    <div class="user-card">
      <h3><%= @user.name %></h3>
    </div>
    """
  end
end
```

### Testing Standards

```elixir
# ✅ CORRECT - Use expect (fails if not called)
expect(MyModule, :function_name, fn args ->
  {:ok, "response"}
end)

# ❌ INCORRECT - Don't use stub (allows unused mocks)
stub(MyModule, :function_name, fn args ->
  {:ok, "response"}
end)

# ✅ CORRECT - Use generators for setup, only test one action
test "create guild with valid params" do
  user = generate(user_generator())
  {:ok, guild} = Guilds.create_guild(user, %{name: "Test Guild"})
  assert guild.name == "Test Guild"
end
```

## Project Structure

```
notes/
├── [topic-name]/         # Four-phase workflow outputs
│   ├── research.md       # Phase 1: Codebase impact analysis
│   ├── plan.md          # Phase 2: Strategic planning
│   └── breakdown.md     # Phase 3: Task decomposition
├── features/            # Feature planning documents
├── fixes/              # Bug fix planning documents
├── tasks/              # Simple task planning documents
├── research/           # General research (e.g., designing-a-tui-for-ash-admin.md)
├── planning/           # Planning documents
├── reviews/            # Review documents
└── summaries/          # Summary documents

.claude/
├── agent-definitions/  # Specialized agent configurations
├── commands/          # Custom slash commands
├── AGENTS.md         # Agent orchestration guide
├── HOOKS-GUIDE.md    # Hook configuration guide
└── AGENT-SYSTEM-GUIDE.md
```

## Development Workflow

### Git Workflow

- Use conventional commits (feat:, fix:, docs:, refactor:, test:, chore:)
- Make small, focused commits for easier analysis and reversion
- Create feature branches: `feature/*`, `fix/*`, `task/*`
- **NEVER mention Claude or AI assistants in commit messages**

### Planning Document Workflow

1. Choose appropriate planner based on complexity:
   - Complex features → `feature-planner`
   - Bug fixes → `fix-planner`
   - Simple tasks → `task-planner`

2. Save planning docs in correct location:
   - `notes/features/` for features
   - `notes/fixes/` for fixes
   - `notes/tasks/` for tasks

3. Keep documents updated as work progresses

### Mandatory Review Phase

**CRITICAL**: No feature or fix is complete without parallel review by ALL review agents:

```
🚀 PARALLEL EXECUTION - Run simultaneously:
├── qa-reviewer
├── security-reviewer
├── consistency-reviewer
├── factual-reviewer
├── redundancy-reviewer
└── senior-engineer-reviewer
```

## Available Commands

Common slash commands configured for this project:

- `/research` - Codebase impact analysis phase
- `/plan` - Strategic implementation planning
- `/breakdown` - Task decomposition into numbered checklists
- `/execute` - Implementation execution
- `/feature` - Feature planning and development
- `/fix` - Bug fix planning and resolution
- `/task` - Simple task planning
- `/review` - Run all review agents in parallel
- `/add-tests` - Systematic test development
- `/fix-tests` - Test failure diagnosis and resolution
- `/document` - Documentation creation
- `/commit` - Create a git commit
- `/pr` - Create a pull request

## Key Resources

### Research Documentation

- `notes/research/designing-a-tui-for-ash-admin.md` - Comprehensive TUI design document covering:
  - AshAdmin web UI overview and functionality mapping
  - TermUI framework capabilities and widget library
  - UI/UX design patterns for terminal interfaces
  - Ash framework integration approach
  - Authentication via AshAuthentication
  - Actor switching and multi-tenancy support

## Communication Standards

### Professional Objectivity

- Prioritize technical accuracy over validation
- Question decisions rather than blindly implementing
- Explain reasoning behind technical choices
- Point out potential issues proactively
- Suggest alternatives when better approaches exist

### Critical Analysis

- Be critical and analytical, not sycophant
- Never use over-the-top validation or excessive praise
- Focus on facts and problem-solving
- Apply rigorous standards to all ideas
- Disagree when necessary with objective guidance

## Implementation Principles

1. **Expert Consultation**: Always consult relevant agents before implementation
2. **Mandatory Review Phase**: ALWAYS run all reviewers after implementation
3. **Right-Sized Planning**: Match planner complexity to task complexity
4. **Parallel When Possible**: Run independent agents simultaneously (especially reviews)
5. **Trust Agent Expertise**: Agents are specialists - follow their guidance
6. **Comprehensive Coverage**: Consult all relevant agents for thorough results
7. **Integration Focus**: Apply agent recommendations directly in implementation

## When Not to Use Agents

These are simple enough to do directly:

- Reading specific files (use Read tool)
- Searching for specific classes (use Glob tool)
- Searching within 2-3 specific files (use Read tool)
- Simple git operations
- Running tests or builds

## Anti-Patterns to Avoid

❌ Don't introduce new dependencies without user approval
❌ Don't assume libraries - discover what's actually in use
❌ Don't skip the mandatory review phase
❌ Don't use `ecto.gen.migration` for Ash resources
❌ Don't use `stub` with Mimic - always use `expect`
❌ Don't call multiple actions in a single test
❌ Don't use pipe operator for single function calls
❌ Don't mention Claude in commit messages
❌ Don't create documentation without user request
