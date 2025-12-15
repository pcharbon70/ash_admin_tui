import Config

# Configuration for ash_admin_tui will be added in later phases
# Environment-specific configuration can be added in:
# - config/dev.exs
# - config/test.exs
# - config/prod.exs

# Import environment specific config if it exists
if File.exists?("#{__DIR__}/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
