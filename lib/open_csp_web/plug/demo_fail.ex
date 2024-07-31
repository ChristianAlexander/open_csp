defmodule OpenCspWeb.Plugs.DemoFail do
  def init(opts) do
    Keyword.put_new(opts, :failure_rate, 0.1)
  end

  def call(conn, opts) do
    failure_rate = Keyword.get(opts, :failure_rate)

    if :rand.uniform() < failure_rate, do: raise("Random failure")

    conn
  end
end
