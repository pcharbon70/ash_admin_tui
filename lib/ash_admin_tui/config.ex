defmodule AshAdminTui.Config do
  @moduledoc """
  Configuration management for AshAdminTui application.

  This module provides functions to read, validate, and access application settings
  from both configuration files and environment variables. Environment variables
  with the `ASH_ADMIN_` prefix take precedence over config file values.

  ## Configuration Keys

  - `:api_url` - Base URL for API endpoints (default: nil)
  - `:log_level` - Logger level (default: :info)
  - `:theme` - UI theme settings (default: :default)

  ## Environment Variable Overrides

  Configuration can be overridden using environment variables with the `ASH_ADMIN_` prefix:

  - `ASH_ADMIN_API_URL` - Overrides `:api_url`
  - `ASH_ADMIN_LOG_LEVEL` - Overrides `:log_level` (values: debug, info, warning, error)
  - `ASH_ADMIN_THEME` - Overrides `:theme`

  ## Examples

      # Get configuration with default
      AshAdminTui.Config.get(:api_url, "http://localhost:4000")

      # Get log level
      AshAdminTui.Config.log_level()

      # Validate configuration
      :ok = AshAdminTui.Config.validate()
  """

  @app :ash_admin_tui

  @doc """
  Retrieves a configuration value with an optional default.

  Environment variables with `ASH_ADMIN_` prefix override config file values.
  Returns the default value if neither source provides a value.

  ## Examples

      iex> AshAdminTui.Config.get(:log_level, :info)
      :info

      iex> AshAdminTui.Config.get(:nonexistent, "default")
      "default"
  """
  @spec get(atom(), any()) :: any()
  def get(key, default \\ nil) do
    # Check environment variable first
    case get_from_env(key) do
      nil ->
        # Fall back to application config
        Application.get_env(@app, key, default)

      value ->
        value
    end
  end

  @doc """
  Validates the application configuration.

  Checks that all required configuration values are present and valid.
  Returns `:ok` if validation succeeds, or `{:error, reason}` if validation fails.

  ## Examples

      iex> AshAdminTui.Config.validate()
      :ok
  """
  @spec validate() :: :ok | {:error, String.t()}
  def validate do
    # For MVP, all configuration is optional
    # Future versions may add required configuration
    with :ok <- validate_log_level(),
         :ok <- validate_theme() do
      :ok
    end
  end

  @doc """
  Returns the configured API URL.

  Can be overridden with the `ASH_ADMIN_API_URL` environment variable.
  """
  @spec api_url() :: String.t() | nil
  def api_url do
    get(:api_url)
  end

  @doc """
  Returns the configured log level.

  Can be overridden with the `ASH_ADMIN_LOG_LEVEL` environment variable.
  Valid values: `:debug`, `:info`, `:warning`, `:error`
  """
  @spec log_level() :: atom()
  def log_level do
    get(:log_level, :info)
  end

  @doc """
  Returns the configured theme.

  Can be overridden with the `ASH_ADMIN_THEME` environment variable.
  """
  @spec theme() :: atom()
  def theme do
    get(:theme, :default)
  end

  # Private Functions

  defp get_from_env(key) do
    env_var_name = key_to_env_var(key)

    case System.get_env(env_var_name) do
      nil -> nil
      "" -> nil
      value -> parse_env_value(key, value)
    end
  end

  defp key_to_env_var(key) do
    key
    |> Atom.to_string()
    |> String.upcase()
    |> then(&"ASH_ADMIN_#{&1}")
  end

  defp parse_env_value(:log_level, value) do
    # Convert string log level to atom
    case String.downcase(value) do
      "debug" -> :debug
      "info" -> :info
      "warning" -> :warning
      "error" -> :error
      _ -> nil
    end
  end

  defp parse_env_value(:theme, value) do
    String.to_atom(value)
  end

  defp parse_env_value(_key, value) do
    # Return string value as-is for other keys
    value
  end

  defp validate_log_level do
    level = log_level()
    valid_levels = [:debug, :info, :warning, :error]

    if level in valid_levels do
      :ok
    else
      {:error, "Invalid log_level: #{inspect(level)}. Must be one of #{inspect(valid_levels)}"}
    end
  end

  defp validate_theme do
    # Theme validation is minimal for MVP
    # Future versions may validate against available themes
    :ok
  end
end
