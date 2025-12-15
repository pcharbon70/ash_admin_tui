import Config

# Development Configuration
# Override settings for local development environment

config :ash_admin_tui,
  # Development API URL (can be overridden with ASH_ADMIN_API_URL)
  api_url: "http://localhost:4000",
  # More verbose logging in development
  log_level: :debug

# Configure logger for development
config :logger,
  level: :debug
