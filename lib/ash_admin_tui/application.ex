defmodule AshAdminTui.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # The TermUI runtime will be added in a later task (1.3.2)
      # {AshAdminTui.UI.Runtime, []}
    ]

    opts = [strategy: :one_for_one, name: AshAdminTui.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
