defmodule AshAdminTui.ConfigTest do
  use ExUnit.Case, async: false

  alias AshAdminTui.Config

  setup do
    # Store original environment variables to restore after tests
    original_api_url = System.get_env("ASH_ADMIN_API_URL")
    original_log_level = System.get_env("ASH_ADMIN_LOG_LEVEL")
    original_theme = System.get_env("ASH_ADMIN_THEME")

    # Store original application config
    original_app_config = Application.get_all_env(:ash_admin_tui)

    # Clear environment variables before each test
    System.delete_env("ASH_ADMIN_API_URL")
    System.delete_env("ASH_ADMIN_LOG_LEVEL")
    System.delete_env("ASH_ADMIN_THEME")

    on_exit(fn ->
      # Clear environment variables after test
      System.delete_env("ASH_ADMIN_API_URL")
      System.delete_env("ASH_ADMIN_LOG_LEVEL")
      System.delete_env("ASH_ADMIN_THEME")

      # Restore original environment variables
      restore_env("ASH_ADMIN_API_URL", original_api_url)
      restore_env("ASH_ADMIN_LOG_LEVEL", original_log_level)
      restore_env("ASH_ADMIN_THEME", original_theme)

      # Restore original application config
      Enum.each(Application.get_all_env(:ash_admin_tui), fn {key, _value} ->
        Application.delete_env(:ash_admin_tui, key)
      end)

      Enum.each(original_app_config, fn {key, value} ->
        Application.put_env(:ash_admin_tui, key, value)
      end)
    end)

    :ok
  end

  describe "get/2" do
    test "retrieves configured values from application config" do
      Application.put_env(:ash_admin_tui, :test_key, "test_value")

      assert Config.get(:test_key) == "test_value"
    end

    test "returns default when key is missing" do
      assert Config.get(:nonexistent_key, "default_value") == "default_value"
    end

    test "returns nil as default when no default provided" do
      assert Config.get(:nonexistent_key) == nil
    end

    test "returns configured value over default" do
      Application.put_env(:ash_admin_tui, :test_key, "configured")

      assert Config.get(:test_key, "default") == "configured"
    end

    test "environment variable overrides application config" do
      Application.put_env(:ash_admin_tui, :api_url, "http://config.example.com")
      System.put_env("ASH_ADMIN_API_URL", "http://env.example.com")

      assert Config.get(:api_url) == "http://env.example.com"
    end

    test "ignores empty environment variables" do
      Application.put_env(:ash_admin_tui, :api_url, "http://config.example.com")
      System.put_env("ASH_ADMIN_API_URL", "")

      assert Config.get(:api_url) == "http://config.example.com"
    end
  end

  describe "validate/0" do
    test "succeeds with valid configuration" do
      assert Config.validate() == :ok
    end

    test "succeeds with valid log_level" do
      Application.put_env(:ash_admin_tui, :log_level, :debug)
      assert Config.validate() == :ok

      Application.put_env(:ash_admin_tui, :log_level, :info)
      assert Config.validate() == :ok

      Application.put_env(:ash_admin_tui, :log_level, :warning)
      assert Config.validate() == :ok

      Application.put_env(:ash_admin_tui, :log_level, :error)
      assert Config.validate() == :ok
    end

    test "fails with invalid log_level" do
      Application.put_env(:ash_admin_tui, :log_level, :invalid)

      assert {:error, message} = Config.validate()
      assert message =~ "Invalid log_level"
    end

    test "succeeds with any theme value" do
      Application.put_env(:ash_admin_tui, :theme, :custom)
      assert Config.validate() == :ok
    end
  end

  describe "environment variable overrides" do
    test "ASH_ADMIN_API_URL overrides api_url" do
      System.put_env("ASH_ADMIN_API_URL", "http://env-override.example.com")

      assert Config.get(:api_url) == "http://env-override.example.com"
      assert Config.api_url() == "http://env-override.example.com"
    end

    test "ASH_ADMIN_LOG_LEVEL overrides log_level" do
      System.put_env("ASH_ADMIN_LOG_LEVEL", "debug")
      assert Config.get(:log_level) == :debug
      assert Config.log_level() == :debug

      System.put_env("ASH_ADMIN_LOG_LEVEL", "warning")
      assert Config.get(:log_level) == :warning
      assert Config.log_level() == :warning

      System.put_env("ASH_ADMIN_LOG_LEVEL", "ERROR")
      assert Config.get(:log_level) == :error
      assert Config.log_level() == :error
    end

    test "ASH_ADMIN_LOG_LEVEL handles invalid values" do
      System.put_env("ASH_ADMIN_LOG_LEVEL", "invalid")
      # Should fall back to application config when env var is invalid
      # In test environment, application config has log_level: :warning
      assert Config.log_level() == :warning
    end

    test "ASH_ADMIN_THEME overrides theme" do
      System.put_env("ASH_ADMIN_THEME", "custom")

      assert Config.get(:theme) == :custom
      assert Config.theme() == :custom
    end

    test "multiple environment variables work together" do
      System.put_env("ASH_ADMIN_API_URL", "http://test.example.com")
      System.put_env("ASH_ADMIN_LOG_LEVEL", "debug")
      System.put_env("ASH_ADMIN_THEME", "dark")

      assert Config.api_url() == "http://test.example.com"
      assert Config.log_level() == :debug
      assert Config.theme() == :dark
    end
  end

  describe "api_url/0" do
    test "returns configured api_url" do
      Application.put_env(:ash_admin_tui, :api_url, "http://config.example.com")

      assert Config.api_url() == "http://config.example.com"
    end

    test "returns nil when not configured" do
      Application.delete_env(:ash_admin_tui, :api_url)

      assert Config.api_url() == nil
    end

    test "returns environment variable value" do
      System.put_env("ASH_ADMIN_API_URL", "http://env.example.com")

      assert Config.api_url() == "http://env.example.com"
    end
  end

  describe "log_level/0" do
    test "returns configured log_level" do
      Application.put_env(:ash_admin_tui, :log_level, :debug)

      assert Config.log_level() == :debug
    end

    test "returns default when not configured" do
      Application.delete_env(:ash_admin_tui, :log_level)

      # In test environment, default is :info if not configured
      assert Config.log_level() == :info
    end

    test "returns environment variable value" do
      System.put_env("ASH_ADMIN_LOG_LEVEL", "error")

      assert Config.log_level() == :error
    end
  end

  describe "theme/0" do
    test "returns configured theme" do
      Application.put_env(:ash_admin_tui, :theme, :custom)

      assert Config.theme() == :custom
    end

    test "returns default :default when not configured" do
      Application.delete_env(:ash_admin_tui, :theme)

      assert Config.theme() == :default
    end

    test "returns environment variable value" do
      System.put_env("ASH_ADMIN_THEME", "dark")

      assert Config.theme() == :dark
    end
  end

  describe "configuration precedence" do
    test "environment variable > application config > default" do
      # Set all three levels
      System.put_env("ASH_ADMIN_API_URL", "http://env.example.com")
      Application.put_env(:ash_admin_tui, :api_url, "http://config.example.com")

      # Environment variable wins
      assert Config.get(:api_url, "http://default.example.com") == "http://env.example.com"
    end

    test "application config > default when no environment variable" do
      System.delete_env("ASH_ADMIN_API_URL")
      Application.put_env(:ash_admin_tui, :api_url, "http://config.example.com")

      # Application config wins
      assert Config.get(:api_url, "http://default.example.com") == "http://config.example.com"
    end

    test "default when no environment variable or application config" do
      System.delete_env("ASH_ADMIN_API_URL")
      Application.delete_env(:ash_admin_tui, :api_url)

      # Default wins
      assert Config.get(:api_url, "http://default.example.com") == "http://default.example.com"
    end
  end

  # Helper function to restore environment variables
  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
