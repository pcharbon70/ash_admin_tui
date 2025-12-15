import Config

# AshAdminTui Configuration
# Configure application-wide settings that can be overridden by environment-specific
# config files or environment variables (ASH_ADMIN_* prefix)

config :ash_admin_tui,
  # API URL for connecting to Ash applications
  # Can be overridden with ASH_ADMIN_API_URL environment variable
  api_url: nil,
  # Logger level: :debug, :info, :warning, or :error
  # Can be overridden with ASH_ADMIN_LOG_LEVEL environment variable
  log_level: :info,
  # UI theme settings
  # Can be overridden with ASH_ADMIN_THEME environment variable
  theme: :default

# Logger Configuration
config :logger,
  level: :info

# Import environment specific config if it exists
if File.exists?("#{__DIR__}/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
