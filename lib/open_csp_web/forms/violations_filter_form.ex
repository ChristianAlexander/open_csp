defmodule OpenCspWeb.Forms.ViolationsFilterForm do
  import Ecto.Changeset

  alias OpenCsp.Reporting.CspViolation

  @fields %{
    page_limit: :integer,
    page: :integer,
    q: :string,
    disposition: {
      :parameterized,
      Ecto.Enum,
      Ecto.Enum.init(values: CspViolation.dispositions())
    },
    happened_before: :utc_datetime,
    happened_after: :utc_datetime
  }
  @default_values %{
    page_limit: 50,
    page: 1,
    q: "",
    disposition: nil,
    happened_before: nil,
    happened_after: nil
  }

  def parse(params) do
    {@default_values, @fields}
    |> cast(params, Map.keys(@fields))
    |> validate_number(:page_limit, greater_than: 0, less_than_or_equal_to: 500)
    |> validate_number(:page, greater_than: 0)
    |> apply_action(:parse)
  end

  def default(), do: @default_values

  def live?(%{page: page, happened_before: happened_before}) do
    page == 1 and is_nil(happened_before)
  end
end
