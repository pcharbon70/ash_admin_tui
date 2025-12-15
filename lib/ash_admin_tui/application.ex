defmodule AshAdminTui.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # TermUI Runtime GenServer with permanent restart strategy
      {AshAdminTui.UI.Runtime, []}
    ]

    opts = [strategy: :one_for_one, name: AshAdminTui.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
