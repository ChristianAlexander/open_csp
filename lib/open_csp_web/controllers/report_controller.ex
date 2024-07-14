defmodule OpenCspWeb.ReportController do
  use OpenCspWeb, :controller

  def cors(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> put_resp_header("access-control-max-age", "86400")
    |> send_resp(200, "OK")
  end

  def handle_report(conn, %{_json: reports}) do
    reports
    |> Enum.map(&parse_report/1)
    |> dbg

    conn
    |> put_status(201)
    |> json(%{message: "Report received"})
  end

  def handle_report(conn, _) do
    conn
    |> put_status(400)
    |> json(%{error: "Invalid report"})
  end

  defp parse_report(%{"type" => "csp-violation"} = report) do
    {:ok, report}
  end

  defp parse_report(report) do
    {:error, "Unsupported or invalid report"}
  end
end
