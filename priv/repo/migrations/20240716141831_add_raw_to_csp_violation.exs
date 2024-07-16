defmodule OpenCsp.Repo.Migrations.AddRawToCspViolation do
  use Ecto.Migration

  def change do
    alter table("csp_violations") do
      add :raw, :map, default: %{}
    end
  end
end
