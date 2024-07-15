defmodule OpenCspWeb.Live.Violations do
  use OpenCspWeb, :live_view

  alias OpenCsp.Reporting

  import SaladUI.Badge
  import SaladUI.Button
  import SaladUI.DropdownMenu
  import SaladUI.Menu
  import SaladUI.Table

  @max_page_limit 500

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OpenCsp.PubSub, "violations:all")
    end

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    page_limit =
      case Integer.parse(Map.get(params, "page_limit", "")) do
        :error -> 50
        {page_limit, _} -> min(page_limit, @max_page_limit)
      end

    filters = Map.get(params, "filters", []) |> as_validated_filters()

    socket =
      socket
      |> assign(page_limit: page_limit)
      |> assign(filters: filters)
      |> refetch_violations()

    {:noreply, socket}
  end

  def handle_info({:new_violation, violation}, socket) do
    if matches_filters?(violation, socket.assigns.filters) do
      {:noreply,
       stream_insert(socket, :violations, violation, at: 0, limit: socket.assigns.page_limit)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filter-disposition", %{"disposition" => disposition}, socket) do
    filters = Keyword.put(socket.assigns.filters, :disposition, disposition)

    socket =
      socket |> assign(filters: filters)

    {:noreply, push_patch(socket, to: filtered_path(socket))}
  end

  def handle_event("filter-disposition", _, socket) do
    filters = Keyword.delete(socket.assigns.filters, :disposition)

    socket =
      socket |> assign(filters: filters)

    {:noreply, push_patch(socket, to: filtered_path(socket))}
  end

  defp refetch_violations(socket) do
    filters = socket.assigns.filters
    page_limit = socket.assigns.page_limit

    violations =
      Reporting.list_csp_violations(%{
        sort_by: :happened_at,
        sort_order: :desc,
        limit: page_limit,
        filters: filters
      })

    stream(socket, :violations, violations, limit: page_limit, reset: true)
  end

  defp filtered_path(socket) do
    query_params = %{
      filters: socket.assigns.filters |> Enum.map(&as_query_param/1) |> dbg,
      page_limit: socket.assigns.page_limit
    }

    ~p"/violations?#{query_params}"
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

  def render(assigns) do
    ~H"""
    <div class="mb-8 float-right">
      <.dropdown_menu>
        <.dropdown_menu_trigger>
          <.button variant="outline">Filters</.button>
        </.dropdown_menu_trigger>
        <.dropdown_menu_content align="end">
          <.menu class="w-56">
            <% current_disposition = Keyword.get(@filters, :disposition, "all") %>
            <.menu_label>Action</.menu_label>
            <.menu_group>
              <.menu_item phx-click="filter-disposition" disabled={current_disposition == "all"}>
                <.icon :if={current_disposition == "all"} name="hero-check" class="h-3 w-3 mr-2" />
                <span>All</span>
              </.menu_item>
              <.menu_item
                phx-click="filter-disposition"
                phx-value-disposition="enforce"
                disabled={current_disposition == "enforce"}
              >
                <.icon :if={current_disposition == "enforce"} name="hero-check" class="h-3 w-3 mr-2" />
                <span>Enforce</span>
              </.menu_item>
              <.menu_item
                phx-click="filter-disposition"
                phx-value-disposition="report"
                disabled={current_disposition == "report"}
              >
                <.icon :if={current_disposition == "report"} name="hero-check" class="h-3 w-3 mr-2" />
                <span>Report</span>
              </.menu_item>
            </.menu_group>
          </.menu>
        </.dropdown_menu_content>
      </.dropdown_menu>
    </div>
    <.table>
      <.table_header>
        <.table_row>
          <.table_head>Action</.table_head>
          <.table_head>Time (UTC)</.table_head>
          <.table_head>URI</.table_head>
          <.table_head>Directive</.table_head>
          <.table_head>Blocked URI</.table_head>
          <.table_head>Browser</.table_head>
        </.table_row>
      </.table_header>
      <.table_body id="violations" phx-update="stream">
        <.table_row :for={{dom_id, violation} <- @streams.violations} id={dom_id}>
          <% ua = UAParser.parse(violation.user_agent) %>
          <.table_cell>
            <.badge variant={
              if violation.disposition == :enforce, do: "destructive", else: "secondary"
            }>
              <%= violation.disposition %>
            </.badge>
          </.table_cell>
          <.table_cell><%= violation.happened_at %></.table_cell>
          <.table_cell><%= violation.url %></.table_cell>
          <.table_cell><%= violation.effective_directive %></.table_cell>
          <.table_cell><%= violation.blocked_url %></.table_cell>
          <.table_cell>
            <%= to_string(ua) %>
            <%= ua.os.family %>
          </.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end
end
