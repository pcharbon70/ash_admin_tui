defmodule ProjectStructureTest do
  use ExUnit.Case
  doctest AshAdminTui

  describe "mix.exs compilation" do
    test "mix.exs compiles without errors" do
      # Verify that mix.exs exists and is a valid Elixir file
      assert File.exists?("mix.exs")

      # Verify the project configuration is accessible
      project = Mix.Project.config()
      assert is_list(project)

      # Verify key project settings
      assert project[:app] == :ash_admin_tui
      assert project[:version] == "0.1.0"
      assert project[:elixir] == "~> 1.14"
    end

    test "mix.exs has proper metadata" do
      project = Mix.Project.config()

      # Verify description exists
      assert is_binary(project[:description])
      assert String.contains?(project[:description], "Terminal User Interface")

      # Verify package metadata
      package = project[:package]
      assert is_list(package)
      assert package[:name] == "ash_admin_tui"
      assert package[:licenses] == ["MIT"]
    end

    test "mix.exs defines dependencies function" do
      # Verify deps/0 function exists and returns a list
      deps = Mix.Project.config()[:deps]
      assert is_list(deps)
    end
  end

  describe "application module" do
    test "application module exists and loads" do
      # Verify the main application module exists
      assert Code.ensure_loaded?(AshAdminTui)
    end

    test "application module has version function" do
      # Verify the version/0 function exists
      assert function_exported?(AshAdminTui, :version, 0)

      # Verify it returns a string
      version = AshAdminTui.version()
      assert is_binary(version)
    end

    test "OTP application module exists" do
      # Verify Application module exists
      assert Code.ensure_loaded?(AshAdminTui.Application)
    end

    test "application start function is defined" do
      # Verify start/2 callback exists
      assert function_exported?(AshAdminTui.Application, :start, 2)
    end

    test "application is configured in mix.exs" do
      # Verify application configuration using Application.spec
      # The application must be started for this to work
      Application.ensure_all_started(:ash_admin_tui)

      mod = Application.spec(:ash_admin_tui, :mod)
      assert mod == {AshAdminTui.Application, []}

      # Verify applications includes logger (extra_applications become applications)
      apps = Application.spec(:ash_admin_tui, :applications)
      assert :logger in apps
    end
  end

  describe "directory structure" do
    test "lib directory structure exists" do
      assert File.dir?("lib")
      assert File.dir?("lib/ash_admin_tui")
      assert File.exists?("lib/ash_admin_tui.ex")
      assert File.exists?("lib/ash_admin_tui/application.ex")
    end

    test "UI components directory exists" do
      assert File.dir?("lib/ash_admin_tui/ui")
    end

    test "core logic directory exists" do
      assert File.dir?("lib/ash_admin_tui/core")
    end

    test "Mix tasks directory exists" do
      assert File.dir?("lib/mix")
      assert File.dir?("lib/mix/tasks")
    end

    test "test directory structure exists" do
      assert File.dir?("test")
      assert File.exists?("test/test_helper.exs")
      assert File.dir?("test/support")
    end

    test "config directory exists" do
      assert File.dir?("config")
      assert File.exists?("config/config.exs")
    end

    test "documentation files exist" do
      assert File.exists?("README.md")
      assert File.exists?("LICENSE.md")
      assert File.exists?("CLAUDE.md")
    end

    test "notes directory structure exists" do
      assert File.dir?("notes")
      assert File.dir?("notes/planning")
      assert File.dir?("notes/summaries")
    end
  end

  describe ".gitignore" do
    setup do
      gitignore_content = File.read!(".gitignore")
      {:ok, content: gitignore_content}
    end

    test ".gitignore file exists", %{content: content} do
      assert File.exists?(".gitignore")
      assert byte_size(content) > 0
    end

    test "excludes build artifacts", %{content: content} do
      assert content =~ "/_build/"
      assert content =~ "/deps/"
      assert content =~ "*.ez"
    end

    test "excludes coverage reports", %{content: content} do
      assert content =~ "/cover/"
      assert content =~ "/coverage/"
      assert content =~ "*.coverdata"
    end

    test "excludes documentation", %{content: content} do
      assert content =~ "/doc/"
    end

    test "excludes editor files", %{content: content} do
      assert content =~ ".elixir_ls/"
      assert content =~ ".vscode/"
      assert content =~ ".idea/"
      assert content =~ "*.swp"
      assert content =~ ".DS_Store"
    end

    test "excludes environment files", %{content: content} do
      assert content =~ ".env"
    end

    test "excludes Dialyzer PLT files", %{content: content} do
      assert content =~ "*.plt"
      assert content =~ "*.plt.hash"
    end

    test "excludes log files", %{content: content} do
      assert content =~ "*.log"
    end

    test "excludes crash dumps", %{content: content} do
      assert content =~ "erl_crash.dump"
    end

    test "excludes package tarball", %{content: content} do
      assert content =~ "ash_admin_tui-*.tar"
    end
  end
end
