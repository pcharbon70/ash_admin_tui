import Config

# Runtime Configuration
# Configuration that is loaded at application startup, allowing runtime
# environment variables to override compile-time configuration.

# This file is executed when the release starts, making it ideal for
# configuration that depends on environment variables that may not be
# available at compile time.

# API URL from environment variable
if api_url = System.get_env("ASH_ADMIN_API_URL") do
  config :ash_admin_tui, api_url: api_url
end

# Log level from environment variable
if log_level = System.get_env("ASH_ADMIN_LOG_LEVEL") do
  level =
    case String.downcase(log_level) do
      "debug" -> :debug
      "info" -> :info
      "warning" -> :warning
      "error" -> :error
      _ -> :info
    end

  config :ash_admin_tui, log_level: level
  config :logger, level: level
end

# Theme from environment variable
if theme = System.get_env("ASH_ADMIN_THEME") do
  config :ash_admin_tui, theme: String.to_atom(theme)
end
