defmodule OpenCspWeb.ReportController do
  use OpenCspWeb, :controller

  # Allow requests from all origins to collect for reporting
  def cors(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> put_resp_header("access-control-max-age", "86400")
    |> send_resp(200, "OK")
  end

  # Handle legacy reports, currently used by Firefox
  def handle_report(conn, %{"csp-report" => report}) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()

    report = modernize_report(Map.put(report, "user_agent", user_agent))

    handle_report(conn, %{"_json" => [report]})
  end

  # Handle single report, currently used by Safari
  def handle_report(conn, %{"type" => "csp-violation"} = report) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()
    report = Map.put(report, "user_agent", user_agent)

    handle_report(conn, %{"_json" => [report]})
  end

  # Handle the latest report format, used by Chrome
  def handle_report(conn, %{"_json" => reports}) do
    remote_ip =
      case :inet.ntoa(conn.remote_ip) do
        {:error, _} -> "unknown"
        ip -> to_string(ip)
      end

    case OpenCsp.Reporting.create_violations_from_request(reports, remote_ip) do
      {:ok, _} ->
        conn
        |> put_status(201)
        |> json(%{message: "Report received"})

      {:error, _, %Ecto.Changeset{}, _} ->
        conn
        |> put_status(400)
        |> text("Invalid report")

      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_status(500)
        |> text("Internal server error")
    end
  end

  def handle_report(conn, _) do
    conn
    |> put_status(400)
    |> text("Unsupported report format")
  end

  defp modernize_report(old_report) do
    %{
      "age" => 0,
      "type" => "csp-violation",
      "url" => old_report["document-uri"],
      "user_agent" => old_report["user_agent"],
      "body" => %{
        "blockedURL" => old_report["blocked-uri"],
        "disposition" => old_report["disposition"],
        "documentURL" => old_report["document-uri"],
        "effectiveDirective" => old_report["effective-directive"],
        "originalPolicy" => old_report["original-policy"],
        "referrer" => old_report["referrer"],
        "statusCode" => old_report["status-code"]
      }
    }
  end
end
