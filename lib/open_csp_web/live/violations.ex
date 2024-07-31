defmodule OpenCspWeb.Live.Violations do
  use OpenCspWeb, :live_view

  alias OpenCsp.Reporting

  import SaladUI.Badge
  import SaladUI.DropdownMenu
  import SaladUI.Menu
  import SaladUI.Pagination
  import SaladUI.Separator
  import SaladUI.Sheet
  import SaladUI.Table

  import OpenCspWeb.Components.Pagination

  def handle_params(params, _uri, socket) do
    parsed_values = OpenCspWeb.Forms.Violations.parse(params)

    if connected?(socket) do
      Phoenix.PubSub.unsubscribe(OpenCsp.PubSub, "violations:all")

      if parsed_values.live? do
        Phoenix.PubSub.subscribe(OpenCsp.PubSub, "violations:all")
      end
    end

    socket =
      socket
      |> assign(parsed_values)
      |> refetch_violations()

    {:noreply, socket}
  end

  def handle_info({:new_violation, violation}, socket) do
    if socket.assigns.live? and
         matches_filters?(violation, socket.assigns.filters) and
         matches_search?(violation, socket.assigns.search_value) do
      socket =
        socket
        |> stream_insert(:violations, violation, at: 0, limit: socket.assigns.page_limit)
        |> assign(total_count: socket.assigns.total_count + 1)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filter-disposition", %{"disposition" => disposition}, socket) do
    filters = Keyword.put(socket.assigns.filters, :disposition, disposition)

    socket =
      socket |> assign(filters: filters, page: 1)

    {:noreply, push_patch(socket, to: filtered_path(socket.assigns), replace: true)}
  end

  def handle_event("filter-disposition", _, socket) do
    filters = Keyword.delete(socket.assigns.filters, :disposition)

    socket =
      socket |> assign(filters: filters, page: 1)

    {:noreply, push_patch(socket, to: filtered_path(socket.assigns), replace: true)}
  end

  def handle_event("crash", _, socket) do
    raise "Crash!"
  end

  def handle_event("search", %{"_target" => ["search"], "search" => search_value}, socket) do
    socket =
      socket |> assign(search_value: search_value, page: 1)

    {:noreply, push_patch(socket, to: filtered_path(socket.assigns), replace: true)}
  end

  def handle_event("page-size", %{"size" => size}, socket) do
    socket =
      socket
      |> assign(page_limit: size)
      |> assign(page: 1)

    {:noreply, push_patch(socket, to: filtered_path(socket.assigns), replace: true)}
  end

  defp refetch_violations(socket) do
    page_limit = socket.assigns.page_limit

    %{violations: violations, total_count: total_count} =
      Reporting.list_csp_violations(%{
        sort_by: :happened_at,
        sort_order: :desc,
        limit: page_limit,
        filters: socket.assigns.filters,
        search_value: socket.assigns.search_value,
        page: socket.assigns.page
      })

    socket
    |> stream(:violations, violations, limit: page_limit, reset: true)
    |> assign(total_count: total_count)
  end

  defp filtered_path_for_page(assigns, page) when is_integer(page) do
    assigns =
      assigns
      |> Map.put(:page, page)
      |> Map.update(:filters, [], fn filters ->
        Keyword.put_new_lazy(filters, :happened_before, fn ->
          DateTime.utc_now()
        end)
      end)

    filtered_path(assigns)
  end

  defp filtered_path_for_live(assigns) do
    assigns =
      assigns
      |> Map.put(:page, 1)
      |> Map.update(:filters, [], fn filters ->
        Keyword.delete(filters, :happened_before)
      end)

    filtered_path(assigns)
  end

  defp filtered_path(assigns) do
    ~p"/violations?#{query_params(assigns)}"
  end

  defp query_params(assigns) do
    %{
      filters: assigns.filters |> Enum.map(&as_query_param/1),
      page_limit: assigns.page_limit,
      q: assigns.search_value,
      page: assigns.page
    }
  end

  defp as_query_param({key, %DateTime{} = value}) do
    {key, DateTime.to_iso8601(value)}
  end

  defp as_query_param({key, value}), do: {key, value}

  defp matches_filters?(violation, filters) do
    Enum.all?(filters, fn
      {:disposition, disposition} ->
        to_string(violation.disposition) == disposition

      {:happened_before, instant} ->
        DateTime.before?(violation.happened_at, instant)

      {:happened_after, instant} ->
        not DateTime.before?(violation.happened_at, instant)
    end)
  end

  defp matches_search?(_, ""), do: true

  defp matches_search?(violation, search_value) do
    search_value
    |> String.trim()
    |> String.downcase()
    |> String.split(~r/\s+/)
    |> Enum.any?(fn term ->
      String.contains?(String.downcase(violation.url), term) or
        String.contains?(String.downcase(violation.blocked_url), term)
    end)
  end

  defp page_count(%{page_limit: page_size, page: current_page, total_count: total_count}) do
    ceil(total_count / page_size)
  end

  defp pages(%{page: current_page} = assigns) do
    for page_number <- 1..page_count(assigns)//1, abs(page_number - current_page) <= 2 do
      current_page? = page_number == current_page
      {page_number, current_page?}
    end
  end
end
