defmodule OpenCsp.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias OpenCsp.Repo

  alias OpenCsp.Reporting.CspViolation

  @doc """
  Returns the list of csp_violations.

  ## Examples

      iex> list_csp_violations()
      [%CspViolation{}, ...]

  """
  def list_csp_violations do
    Repo.all(CspViolation)
  end

  @doc """
  Gets a single csp_violation.

  Raises `Ecto.NoResultsError` if the Csp violation does not exist.

  ## Examples

      iex> get_csp_violation!(123)
      %CspViolation{}

      iex> get_csp_violation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_csp_violation!(id), do: Repo.get!(CspViolation, id)

  @doc """
  Creates a csp_violation.

  ## Examples

      iex> create_csp_violation(%{field: value})
      {:ok, %CspViolation{}}

      iex> create_csp_violation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_csp_violation(attrs \\ %{}) do
    %CspViolation{}
    |> CspViolation.changeset(attrs)
    |> Repo.insert()
  end

  def create_violations_from_request(reports, remote_ip) do
    reports
    |> Enum.filter(&(&1["type"] == "csp-violation"))
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {report, index}, multi ->
      changeset = CspViolation.from_report(report, remote_ip)
      Ecto.Multi.insert(multi, index, changeset)
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a csp_violation.

  ## Examples

      iex> update_csp_violation(csp_violation, %{field: new_value})
      {:ok, %CspViolation{}}

      iex> update_csp_violation(csp_violation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_csp_violation(%CspViolation{} = csp_violation, attrs) do
    csp_violation
    |> CspViolation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a csp_violation.

  ## Examples

      iex> delete_csp_violation(csp_violation)
      {:ok, %CspViolation{}}

      iex> delete_csp_violation(csp_violation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_csp_violation(%CspViolation{} = csp_violation) do
    Repo.delete(csp_violation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking csp_violation changes.

  ## Examples

      iex> change_csp_violation(csp_violation)
      %Ecto.Changeset{data: %CspViolation{}}

  """
  def change_csp_violation(%CspViolation{} = csp_violation, attrs \\ %{}) do
    CspViolation.changeset(csp_violation, attrs)
  end
end
