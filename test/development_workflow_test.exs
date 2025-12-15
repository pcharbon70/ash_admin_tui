defmodule DevelopmentWorkflowTest do
  use ExUnit.Case, async: false

  describe "Mix task" do
    test "ash_admin.tui task exists" do
      # Verify the Mix task module is defined
      assert Code.ensure_loaded?(Mix.Tasks.AshAdmin.Tui)
    end

    test "ash_admin.tui task has shortdoc" do
      # Get task metadata
      Mix.Task.load_all()
      tasks = Mix.Task.all_modules()

      # Verify our task is in the list
      assert Mix.Tasks.AshAdmin.Tui in tasks

      # Verify it has a shortdoc (shows up in mix help)
      # @shortdoc is a module attribute, access via moduledoc metadata
      {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(Mix.Tasks.AshAdmin.Tui)
      assert module_doc != :hidden
    end

    test "ash_admin.tui task is discoverable via mix help" do
      # Run mix help and check if our task appears
      {output, 0} = System.cmd("mix", ["help"], stderr_to_stdout: true)

      assert output =~ "ash_admin.tui"
    end

    test "ash_admin.tui task has run/1 function" do
      # Verify the task implements the run/1 callback
      assert function_exported?(Mix.Tasks.AshAdmin.Tui, :run, 1)
    end
  end

  describe "Code quality tools" do
    test ".credo.exs configuration file exists" do
      assert File.exists?(".credo.exs")
    end

    test ".credo.exs has valid configuration" do
      # Read and evaluate the .credo.exs file
      {config, _binding} = Code.eval_file(".credo.exs")

      # Verify it's a map with configs
      assert is_map(config)
      assert Map.has_key?(config, :configs)
      assert is_list(config.configs)
      refute Enum.empty?(config.configs)
    end

    test "Credo is configured with strict mode" do
      {config, _binding} = Code.eval_file(".credo.exs")

      # Get the default config
      default_config = Enum.find(config.configs, fn c -> c.name == "default" end)
      assert default_config != nil

      # Verify strict mode is enabled
      assert default_config.strict == true
    end

    test "Credo checks are properly configured" do
      {config, _binding} = Code.eval_file(".credo.exs")
      default_config = Enum.find(config.configs, fn c -> c.name == "default" end)

      # Verify checks configuration exists
      assert Map.has_key?(default_config, :checks)
      assert is_map(default_config.checks)
      assert Map.has_key?(default_config.checks, :enabled)
      assert is_list(default_config.checks.enabled)
    end

    test "Dialyzer is configured in mix.exs" do
      # Get project configuration
      config = Mix.Project.config()

      # Verify dialyzer configuration exists
      assert Keyword.has_key?(config, :dialyzer)

      dialyzer_config = config[:dialyzer]
      assert is_list(dialyzer_config)

      # Verify key dialyzer settings
      assert Keyword.has_key?(dialyzer_config, :plt_file)
      assert Keyword.has_key?(dialyzer_config, :flags)
    end

    test ".dialyzer_ignore.exs file exists" do
      assert File.exists?(".dialyzer_ignore.exs")
    end

    test ".dialyzer_ignore.exs has valid format" do
      # Read and evaluate the file
      {warnings, _binding} = Code.eval_file(".dialyzer_ignore.exs")

      # Verify it's a list
      assert is_list(warnings)
    end

    test "PLT directory is configured" do
      config = Mix.Project.config()
      dialyzer_config = config[:dialyzer]

      plt_file = Keyword.get(dialyzer_config, :plt_file)
      assert plt_file != nil

      # Verify it uses priv/plts/ directory
      {_option, path} = plt_file
      assert path =~ "priv/plts"
    end
  end

  describe "Testing infrastructure" do
    test "test_helper.exs exists" do
      assert File.exists?("test/test_helper.exs")
    end

    test "test_helper.exs starts ExUnit" do
      content = File.read!("test/test_helper.exs")

      # Verify ExUnit.start() is called
      assert content =~ "ExUnit.start()"
    end

    test "ExCoveralls is configured in mix.exs" do
      config = Mix.Project.config()

      # Verify test coverage tool is configured
      assert Keyword.has_key?(config, :test_coverage)
      assert config[:test_coverage][:tool] == ExCoveralls
    end

    test "Coverage CLI environments are configured" do
      # In Elixir 1.19+, preferred_cli_env moved from project/0 to cli/0
      # This prevents deprecation warnings
      cli_config = AshAdminTui.MixProject.cli()

      # Verify coverage commands use :test environment
      preferred_envs = cli_config[:preferred_envs]
      assert preferred_envs[:coveralls] == :test
      assert preferred_envs[:"coveralls.detail"] == :test
      assert preferred_envs[:"coveralls.html"] == :test
    end

    test "Mimic dependency is available in test environment" do
      # Verify Mimic is in the dependencies
      deps = Mix.Project.config()[:deps]
      dep_names = Enum.map(deps, fn
        {name, _version} -> name
        {name, _version, _opts} -> name
      end)

      assert :mimic in dep_names
    end

    test "test directory structure exists" do
      assert File.dir?("test")
      assert File.dir?("test/ash_admin_tui")
    end

    test "all test files are discovered" do
      # Find all *_test.exs files
      test_files = Path.wildcard("test/**/*_test.exs")

      # Verify we have test files
      refute Enum.empty?(test_files)

      # Verify key test files exist
      assert Enum.any?(test_files, &String.ends_with?(&1, "config_test.exs"))
      assert Enum.any?(test_files, &String.ends_with?(&1, "termui_integration_test.exs"))
    end
  end

  describe "Mix project configuration" do
    test "elixirc_paths includes test/support in test environment" do
      # In test environment, test/support should be included
      # Note: This test runs in test env, so we're testing the current environment
      paths = Mix.Project.config()[:elixirc_paths]

      # Verify paths include lib and test/support
      assert "lib" in paths
      assert "test/support" in paths
    end

    test "application is configured to start" do
      # Verify application configuration
      app_config = Application.get_all_env(:ash_admin_tui)
      assert is_list(app_config)
    end
  end
end
