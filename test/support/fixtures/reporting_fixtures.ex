defmodule OpenCsp.ReportingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenCsp.Reporting` context.
  """

  @doc """
  Generate a csp_violation.
  """
  def csp_violation_fixture(attrs \\ %{}) do
    {:ok, csp_violation} =
      attrs
      |> Enum.into(%{
        blocked_url: "some blocked_url",
        disposition: :enforce,
        document_url: "some document_url",
        original_policy: "some original_policy",
        referrer: "some referrer",
        sample: "some sample",
        status_code: 42,
        url: "some url",
        user_agent: "some user_agent"
      })
      |> OpenCsp.Reporting.create_csp_violation()

    csp_violation
  end
end
