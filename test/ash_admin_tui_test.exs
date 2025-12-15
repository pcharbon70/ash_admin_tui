defmodule AshAdminTuiTest do
  use ExUnit.Case
  doctest AshAdminTui

  test "version/0 returns application version" do
    assert is_binary(AshAdminTui.version())
  end
end
