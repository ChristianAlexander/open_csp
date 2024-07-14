defmodule OpenCsp.Repo do
  use Ecto.Repo,
    otp_app: :open_csp,
    adapter: Ecto.Adapters.Postgres
end
