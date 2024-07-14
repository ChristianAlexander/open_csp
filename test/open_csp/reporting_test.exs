defmodule OpenCsp.ReportingTest do
  use OpenCsp.DataCase

  alias OpenCsp.Reporting

  describe "csp_violations" do
    alias OpenCsp.Reporting.CSPViolation

    import OpenCsp.ReportingFixtures

    @invalid_attrs %{url: nil, disposition: nil, status_code: nil, blocked_url: nil, document_url: nil, referrer: nil, original_policy: nil, user_agent: nil, sample: nil}

    test "list_csp_violations/0 returns all csp_violations" do
      csp_violation = csp_violation_fixture()
      assert Reporting.list_csp_violations() == [csp_violation]
    end

    test "get_csp_violation!/1 returns the csp_violation with given id" do
      csp_violation = csp_violation_fixture()
      assert Reporting.get_csp_violation!(csp_violation.id) == csp_violation
    end

    test "create_csp_violation/1 with valid data creates a csp_violation" do
      valid_attrs = %{url: "some url", disposition: :enforce, status_code: 42, blocked_url: "some blocked_url", document_url: "some document_url", referrer: "some referrer", original_policy: "some original_policy", user_agent: "some user_agent", sample: "some sample"}

      assert {:ok, %CSPViolation{} = csp_violation} = Reporting.create_csp_violation(valid_attrs)
      assert csp_violation.url == "some url"
      assert csp_violation.disposition == :enforce
      assert csp_violation.status_code == 42
      assert csp_violation.blocked_url == "some blocked_url"
      assert csp_violation.document_url == "some document_url"
      assert csp_violation.referrer == "some referrer"
      assert csp_violation.original_policy == "some original_policy"
      assert csp_violation.user_agent == "some user_agent"
      assert csp_violation.sample == "some sample"
    end

    test "create_csp_violation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_csp_violation(@invalid_attrs)
    end

    test "update_csp_violation/2 with valid data updates the csp_violation" do
      csp_violation = csp_violation_fixture()
      update_attrs = %{url: "some updated url", disposition: :report, status_code: 43, blocked_url: "some updated blocked_url", document_url: "some updated document_url", referrer: "some updated referrer", original_policy: "some updated original_policy", user_agent: "some updated user_agent", sample: "some updated sample"}

      assert {:ok, %CSPViolation{} = csp_violation} = Reporting.update_csp_violation(csp_violation, update_attrs)
      assert csp_violation.url == "some updated url"
      assert csp_violation.disposition == :report
      assert csp_violation.status_code == 43
      assert csp_violation.blocked_url == "some updated blocked_url"
      assert csp_violation.document_url == "some updated document_url"
      assert csp_violation.referrer == "some updated referrer"
      assert csp_violation.original_policy == "some updated original_policy"
      assert csp_violation.user_agent == "some updated user_agent"
      assert csp_violation.sample == "some updated sample"
    end

    test "update_csp_violation/2 with invalid data returns error changeset" do
      csp_violation = csp_violation_fixture()
      assert {:error, %Ecto.Changeset{}} = Reporting.update_csp_violation(csp_violation, @invalid_attrs)
      assert csp_violation == Reporting.get_csp_violation!(csp_violation.id)
    end

    test "delete_csp_violation/1 deletes the csp_violation" do
      csp_violation = csp_violation_fixture()
      assert {:ok, %CSPViolation{}} = Reporting.delete_csp_violation(csp_violation)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_csp_violation!(csp_violation.id) end
    end

    test "change_csp_violation/1 returns a csp_violation changeset" do
      csp_violation = csp_violation_fixture()
      assert %Ecto.Changeset{} = Reporting.change_csp_violation(csp_violation)
    end
  end
end
