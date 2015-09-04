defmodule Pixie.Backend.Redis.Pool do
  use Supervisor

  def start_link opts do
    Supervisor.start_link __MODULE__, opts
  end

  def init opts do
    pool_name   = Pixie.Backend.Redis.Pool
    pool_opts = [
      name:          {:local, pool_name},
      worker_module: Pixie.Backend.Redis.Connection,
      size:          Keyword.get(opts, :pool_size),
      max_overflow:  0
    ]

    children = [
      :poolboy.child_spec(pool_name, pool_opts, Keyword.get(opts, :redis_url))
    ]

    supervise children, strategy: :one_for_all
  end
end
