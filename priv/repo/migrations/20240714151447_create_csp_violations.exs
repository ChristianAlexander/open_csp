defmodule OpenCsp.Repo.Migrations.CreateCspViolations do
  use Ecto.Migration

  def change do
    create table(:csp_violations) do
      add :happened_at, :utc_datetime
      add :disposition, :string
      add :status_code, :integer
      add :url, :text
      add :blocked_url, :text
      add :document_url, :text
      add :referrer, :text
      add :original_policy, :text
      add :user_agent, :text
      add :sample, :text
      add :effective_directive, :text
      add :remote_ip, :text

      timestamps(type: :utc_datetime)
    end
  end
end
