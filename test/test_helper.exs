# Start ExUnit with coverage enabled
ExUnit.start()

# Set up Mimic for test mocking
# Mimic.copy/1 is used per CLAUDE.md: use expect (not stub)
# Add modules to mock here as needed:
# Mimic.copy(ModuleToMock)

# Ensure terminal is properly reset after all tests complete
# This prevents terminal modes (like mouse tracking) from persisting
# if tests are interrupted or crash
ExUnit.after_suite(fn _results ->
  # Reset terminal to normal mode
  # Disable mouse tracking, alternate screen buffer, and other special modes
  IO.write([
    # Disable mouse tracking modes
    "\e[?1003l",  # Disable all mouse tracking
    "\e[?1006l",  # Disable SGR extended mouse mode
    "\e[?1000l",  # Disable X10 mouse tracking
    # Exit alternate screen buffer if active
    "\e[?1049l",
    # Show cursor
    "\e[?25h",
    # Reset other terminal modes
    "\e[?1002l",  # Disable button event tracking
    "\e[0m"       # Reset all attributes
  ])

  :ok
end)
