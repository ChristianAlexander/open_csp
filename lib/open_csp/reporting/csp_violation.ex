defmodule OpenCsp.Reporting.CspViolation do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @dispositions [:enforce, :report]

  schema "csp_violations" do
    field :url, :string
    field :happened_at, :utc_datetime
    field :disposition, Ecto.Enum, values: @dispositions
    field :status_code, :integer
    field :blocked_url, :string
    field :document_url, :string
    field :referrer, :string
    field :original_policy, :string
    field :user_agent, :string
    field :sample, :string
    field :effective_directive, :string
    field :remote_ip, :string
    field :raw, :map

    timestamps(type: :utc_datetime)
  end

  def dispositions(), do: @dispositions

  @doc false
  def changeset(csp_violation, attrs) do
    csp_violation
    |> cast(attrs, [
      :happened_at,
      :status_code,
      :url,
      :user_agent,
      :remote_ip,
      :raw
    ])
    |> cast_from_body(attrs, [
      :blocked_url,
      :document_url,
      :referrer,
      :original_policy,
      :sample,
      :effective_directive,
      :disposition
    ])
    |> validate_required([
      :happened_at,
      :disposition,
      :url,
      :blocked_url,
      :document_url,
      :original_policy,
      :remote_ip
    ])
  end

  def broadcast_creation(violation) do
    Phoenix.PubSub.broadcast(OpenCsp.PubSub, "violations:all", {:new_violation, violation})
  end

  def from_report(report, remote_ip \\ "") do
    report = normalize_violation_keys(report)

    happened_at =
      case get_in(report, ["age"]) do
        nil -> DateTime.utc_now()
        age -> DateTime.utc_now() |> DateTime.add(-1 * age, :millisecond)
      end

    report = Map.merge(report, %{"happened_at" => happened_at, "remote_ip" => remote_ip})

    changeset(%CspViolation{}, report)
  end

  defp cast_from_body(changeset, params, permitted) do
    body = get_in(params, ["body"]) || %{}

    cast(changeset, body, permitted)
  end

  defp normalize_violation_keys(params) do
    body = get_in(params, ["body"]) || %{}

    body =
      Map.new(body, fn
        {"blockedURL", v} -> {"blocked_url", v}
        {"documentURL", v} -> {"document_url", v}
        {"originalPolicy", v} -> {"original_policy", v}
        {"effectiveDirective", v} -> {"effective_directive", v}
        {"statusCode", v} -> {"status_code", v}
        {k, v} -> {k, v}
      end)

    Map.put(params, "body", body)
  end
end
