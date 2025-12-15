import Config

# Test Configuration
# Override settings for test environment

config :ash_admin_tui,
  # Test API URL (can be overridden with ASH_ADMIN_API_URL)
  api_url: "http://localhost:4001",
  # Less verbose logging in tests
  log_level: :warning

# Configure logger for testing
# Reduce log noise during tests
config :logger,
  level: :warning
