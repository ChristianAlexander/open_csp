defmodule OpenCsp.Repo.Migrations.AddIndexesToUrls do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX csp_violations_url_gin_trgm_idx
        ON csp_violations
        USING gin (url gin_trgm_ops);
    """

    execute """
      CREATE INDEX csp_violations_blocked_url_gin_trgm_idx
        ON csp_violations
        USING gin (blocked_url gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX csp_violations_url_gin_trgm_idx;"
    execute "DROP INDEX csp_violations_blocked_url_gin_trgm_idx;"
  end
end
