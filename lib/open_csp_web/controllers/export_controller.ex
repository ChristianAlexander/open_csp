defmodule OpenCspWeb.ExportController do
  use OpenCspWeb, :controller

  alias OpenCspWeb.Forms.Violations
  alias OpenCsp.Reporting
  alias NimbleCSV.Spreadsheet, as: CSV

  def export_violations(conn, params) do
    parsed_values =
      params
      |> Violations.parse()
      |> Violations.without_pagination()
      |> dbg()

    conn =
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("Content-disposition", "attachment; filename=csp-violations.csv")
      |> send_chunked(200)

    {:ok, conn} =
      OpenCsp.Repo.transaction(fn ->
        Reporting.stream_csp_violations(parsed_values)
        |> Stream.map(&Reporting.CspViolation.to_csv_row/1)
        |> CSV.dump_to_stream()
        |> Enum.reduce(conn, fn line, conn ->
          {:ok, conn} = chunk(conn, line)

          conn
        end)
      end)

    conn
  end
end
