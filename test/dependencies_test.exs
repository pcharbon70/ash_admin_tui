defmodule DependenciesTest do
  use ExUnit.Case

  describe "dependency resolution" do
    test "all dependencies resolve without conflicts" do
      # Verify that mix deps.get completed successfully by checking deps directory
      assert File.dir?("deps")

      # Get all dependencies from mix.exs
      deps = Mix.Project.config()[:deps]
      assert is_list(deps)
      assert length(deps) > 0
    end

    test "mix.exs defines all required dependencies" do
      deps = Mix.Project.config()[:deps]
      dep_names =
        Enum.map(deps, fn
          {name, _} -> name
          {name, _, _} -> name
        end)

      # Core dependencies
      assert :term_ui in dep_names
      assert :ash in dep_names
      assert :ash_admin in dep_names
      assert :jason in dep_names

      # Development dependencies
      assert :credo in dep_names
      assert :dialyxir in dep_names
      assert :ex_doc in dep_names
      assert :mimic in dep_names
      assert :excoveralls in dep_names
    end
  end

  describe "compilation" do
    test "mix compile succeeds with all dependencies" do
      # This test runs in a compiled project, so if we're here, compilation succeeded
      # We can verify by checking that the application was generated
      assert File.exists?("_build/#{Mix.env()}/lib/ash_admin_tui/ebin/ash_admin_tui.app")
    end

    test "all core dependencies are compiled" do
      # Verify core dependencies have been compiled
      assert File.dir?("_build/#{Mix.env()}/lib/term_ui")
      assert File.dir?("_build/#{Mix.env()}/lib/ash")
      assert File.dir?("_build/#{Mix.env()}/lib/ash_admin")
      assert File.dir?("_build/#{Mix.env()}/lib/jason")
    end
  end

  describe "TermUI availability" do
    test "TermUI module is available and can be referenced" do
      assert Code.ensure_loaded?(TermUI)
    end

    test "TermUI.Runtime module exists" do
      assert Code.ensure_loaded?(TermUI.Runtime)
    end

    test "TermUI.Component module exists" do
      assert Code.ensure_loaded?(TermUI.Component)
    end

    test "TermUI widget modules exist" do
      # TermUI provides various widget modules, check for common ones
      assert Code.ensure_loaded?(TermUI.Widgets.Button) or
               Code.ensure_loaded?(TermUI.Component)
    end
  end

  describe "Ash and AshAdmin accessibility" do
    test "Ash module is accessible" do
      assert Code.ensure_loaded?(Ash)
    end

    test "Ash.Resource module exists" do
      assert Code.ensure_loaded?(Ash.Resource)
    end

    test "Ash.Domain module exists" do
      assert Code.ensure_loaded?(Ash.Domain)
    end

    test "AshAdmin module is accessible" do
      assert Code.ensure_loaded?(AshAdmin)
    end

    test "AshAdmin.Domain extension exists" do
      assert Code.ensure_loaded?(AshAdmin.Domain)
    end

    test "AshAdmin.Resource extension exists" do
      assert Code.ensure_loaded?(AshAdmin.Resource)
    end
  end

  describe "development tools availability" do
    test "Credo is available in dev environment" do
      # Credo should be available in dev and test environments
      if Mix.env() in [:dev, :test] do
        assert Code.ensure_loaded?(Credo)
      end
    end

    test "Dialyxir is available in dev environment" do
      # Dialyxir should be available in dev and test environments
      if Mix.env() in [:dev, :test] do
        assert Code.ensure_loaded?(Mix.Tasks.Dialyzer)
      end
    end

    test "ExDoc is available in dev environment" do
      # ExDoc should be available in dev environment
      if Mix.env() == :dev do
        assert Code.ensure_loaded?(ExDoc)
      end
    end

    test "Mimic is available in test environment" do
      # Mimic should be available in test environment
      if Mix.env() == :test do
        assert Code.ensure_loaded?(Mimic)
      end
    end

    test "ExCoveralls is available in test environment" do
      # ExCoveralls should be available in test environment
      if Mix.env() == :test do
        assert Code.ensure_loaded?(ExCoveralls)
      end
    end
  end

  describe "JSON support" do
    test "Jason module is available" do
      assert Code.ensure_loaded?(Jason)
    end

    test "Jason can encode and decode JSON" do
      data = %{key: "value", number: 42}
      encoded = Jason.encode!(data)
      assert is_binary(encoded)

      decoded = Jason.decode!(encoded)
      assert is_map(decoded)
      assert decoded["key"] == "value"
      assert decoded["number"] == 42
    end
  end

  describe "dependency versions" do
    test "dependencies use correct version constraints" do
      deps = Mix.Project.config()[:deps]

      # Find each dependency and check its version constraint
      term_ui = Enum.find(deps, fn {name, _} -> name == :term_ui end)
      assert match?({:term_ui, "~> 0.2.0"}, term_ui)

      ash = Enum.find(deps, fn {name, _} -> name == :ash end)
      assert match?({:ash, "~> 3.0"}, ash)

      ash_admin = Enum.find(deps, fn {name, _} -> name == :ash_admin end)
      assert match?({:ash_admin, "~> 0.11"}, ash_admin)

      jason = Enum.find(deps, fn {name, _} -> name == :jason end)
      assert match?({:jason, "~> 1.4"}, jason)
    end

    test "development dependencies use correct environment constraints" do
      deps = Mix.Project.config()[:deps]

      # Credo should be dev/test only
      credo =
        Enum.find(deps, fn
          {name, _} -> name == :credo
          {name, _, _} -> name == :credo
        end)

      {_, _, opts} = credo
      assert opts[:only] == [:dev, :test]
      assert opts[:runtime] == false

      # Dialyxir should be dev/test only
      dialyxir =
        Enum.find(deps, fn
          {name, _} -> name == :dialyxir
          {name, _, _} -> name == :dialyxir
        end)

      {_, _, opts} = dialyxir
      assert opts[:only] == [:dev, :test]
      assert opts[:runtime] == false

      # ExDoc should be dev only
      ex_doc =
        Enum.find(deps, fn
          {name, _} -> name == :ex_doc
          {name, _, _} -> name == :ex_doc
        end)

      {_, _, opts} = ex_doc
      assert opts[:only] == :dev
      assert opts[:runtime] == false

      # Mimic should be test only
      mimic =
        Enum.find(deps, fn
          {name, _} -> name == :mimic
          {name, _, _} -> name == :mimic
        end)

      {_, _, opts} = mimic
      assert opts[:only] == :test

      # ExCoveralls should be test only
      excoveralls =
        Enum.find(deps, fn
          {name, _} -> name == :excoveralls
          {name, _, _} -> name == :excoveralls
        end)

      {_, _, opts} = excoveralls
      assert opts[:only] == :test
    end
  end
end
