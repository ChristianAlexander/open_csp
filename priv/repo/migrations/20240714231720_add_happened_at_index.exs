defmodule OpenCsp.Repo.Migrations.AddHappenedAtIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists index("csp_violations", [:happened_at])
  end
end
