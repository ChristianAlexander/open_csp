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
  def list_csp_violations(options \\ %{}) do
    query =
      from(CspViolation)
      |> with_filters(options)
      |> with_search(options)

    total_count = Repo.aggregate(query, :count)

    query =
      query
      |> sort(options)
      |> with_pagination(options)

    results = Repo.all(query)

    %{violations: results, total_count: total_count}
  end

  defp sort(query, %{sort_by: sort_by, sort_order: sort_order}) do
    order_by(query, {^sort_order, ^sort_by})
  end

  defp sort(query, _options), do: query

  defp with_filters(query, %{filters: filters}) do
    Enum.reduce(filters, query, &apply_filter/2)
  end

  defp with_filters(query, _options), do: query

  defp apply_filter({:disposition, disposition}, query) do
    where(query, [c], c.disposition == ^disposition)
  end

  defp apply_filter({:happened_after, instant}, query) do
    where(query, [c], c.happened_at >= ^instant)
  end

  defp apply_filter({:happened_before, instant}, query) do
    where(query, [c], c.happened_at < ^instant)
  end

  defp apply_filter(_filter, query), do: query

  defp with_search(query, %{search_value: ""}), do: query

  defp with_search(query, %{search_value: search_value}) do
    wildcard_query = "%#{search_value}%"

    query
    |> where(
      [c],
      ilike(c.url, ^wildcard_query) or
        ilike(c.blocked_url, ^wildcard_query)
    )
  end

  defp with_search(query, _options), do: query

  defp with_pagination(query, %{page: page, limit: limit})
       when is_integer(page) and is_integer(limit) do
    offset = max(page - 1, 0) * limit

    query
    |> limit(^limit)
    |> offset(^offset)
  end

  defp with_pagination(query, %{limit: limit}) do
    limit(query, ^limit)
  end

  defp with_pagination(query, _options), do: query

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
    multi =
      reports
      |> Enum.filter(&(&1["type"] == "csp-violation"))
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn {report, index}, multi ->
        changeset = CspViolation.from_report(report, remote_ip)
        Ecto.Multi.insert(multi, index, changeset)
      end)

    with {:ok, violations} <- Repo.transaction(multi) do
      Enum.each(Map.values(violations), &OpenCsp.Reporting.CspViolation.broadcast_creation/1)
      {:ok, violations}
    else
      error -> error
    end
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
