defmodule OpenCspWeb.Forms.Violations do
  @max_page_limit 500

  def parse(params) do
    page_limit =
      case Integer.parse(Map.get(params, "page_limit", "")) do
        :error -> 50
        {page_limit, _} -> min(page_limit, @max_page_limit)
      end

    page =
      case Integer.parse(Map.get(params, "page", "")) do
        :error -> 1
        {page, _} -> max(page, 1)
      end

    filters = Map.get(params, "filters", []) |> as_validated_filters()

    %{
      page_limit: page_limit,
      page: page,
      filters: filters,
      search_value: Map.get(params, "q", ""),
      live?: page == 1 and not Keyword.has_key?(filters, :happened_before)
    }
  end

  def without_pagination(form) do
    form
    |> Map.delete(:page)
    |> Map.delete(:page_limit)
  end

  defp as_validated_filters(filters) do
    Enum.map(filters, fn
      {"disposition", disposition} when disposition in ["enforce", "report"] ->
        {:disposition, disposition}

      {"happened_before", happened_before} when is_binary(happened_before) ->
        with {:ok, instant, _} <- DateTime.from_iso8601(happened_before) do
          {:happened_before, instant}
        else
          _ ->
            nil
        end

      {"happened_after", happened_after} when is_binary(happened_after) ->
        with {:ok, instant, _} <- DateTime.from_iso8601(happened_after) do
          {:happened_after, instant}
        else
          _ ->
            nil
        end

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Keyword.new()
  end
end
