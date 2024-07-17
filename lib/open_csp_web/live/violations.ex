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

  @max_page_limit 500

  def handle_params(params, _uri, socket) do
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

    live? = page == 1 and not Keyword.has_key?(filters, :happened_before)

    if live? and connected?(socket) do
      Phoenix.PubSub.subscribe(OpenCsp.PubSub, "violations:all")
    else
      Phoenix.PubSub.unsubscribe(OpenCsp.PubSub, "violations:all")
    end

    socket =
      socket
      |> assign(page_limit: page_limit)
      |> assign(filters: filters)
      |> assign(page: page)
      |> assign(search_value: Map.get(params, "q", ""))
      |> assign(live?: live?)
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
    query_params = %{
      filters: assigns.filters |> Enum.map(&as_query_param/1),
      page_limit: assigns.page_limit,
      q: assigns.search_value,
      page: assigns.page
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

  defp page_count(%{page_limit: page_size, page: current_page, total_count: total_count}) do
    ceil(total_count / page_size)
  end

  defp pages(%{page: current_page} = assigns) do
    for page_number <- 1..page_count(assigns)//1, abs(page_number - current_page) <= 2 do
      current_page? = page_number == current_page
      {page_number, current_page?}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mb-4 flex flex-col space-y-2 md:items-end md:justify-between md:space-x-4 md:space-y-0 md:flex-row text-zinc-500">
      <.dropdown_menu class="mt-2">
        <.dropdown_menu_trigger>
          <.button variant="outline">Filters</.button>
        </.dropdown_menu_trigger>
        <.dropdown_menu_content align="start">
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
      <div class="grow">
        <form phx-change="search" class="max-w-xl w-full">
          <.input
            type="text"
            placeholder="Search"
            phx-change="search"
            phx-debounce="500"
            name="search"
            value={@search_value}
          />
        </form>
      </div>
      <div class="flex flex-col items-end space-y-4">
        <form phx-change="page-size" class="inline-flex items-baseline space-x-2">
          <span class="text-nowrap text-sm">Page size</span>
          <.input
            type="select"
            name="size"
            class="min-w-24"
            value={@page_limit}
            options={[5, 10, 20, 50, 100]}
          />
        </form>
        <.pagination class="md:justify-end w-min">
          <.pagination_content>
            <.pagination_item>
              <.pagination_live
                class="px-2"
                is-active={@live?}
                patch={filtered_path_for_live(assigns)}
                replace
              />
            </.pagination_item>
            <.pagination_item :if={@page > 1}>
              <.pagination_previous replace patch={filtered_path_for_page(assigns, @page - 1)} />
            </.pagination_item>
            <.pagination_item :for={{page_number, current_page?} <- pages(assigns)}>
              <.pagination_link
                is-active={current_page? and not @live?}
                replace
                patch={filtered_path_for_page(assigns, page_number)}
              >
                <%= page_number %>
              </.pagination_link>
            </.pagination_item>
            <.pagination_item :if={@page < page_count(assigns)}>
              <.pagination_next replace patch={filtered_path_for_page(assigns, @page + 1)} />
            </.pagination_item>
          </.pagination_content>
        </.pagination>
      </div>
    </div>
    <.table>
      <.table_caption><%= @total_count %> result(s)</.table_caption>
      <.table_header>
        <.table_row>
          <.table_head>Action</.table_head>
          <.table_head>Time (UTC)</.table_head>
          <.table_head>URI</.table_head>
          <.table_head>Directive</.table_head>
          <.table_head>Blocked URI</.table_head>
          <.table_head>Browser</.table_head>
          <.table_head></.table_head>
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
          <.table_cell>
            <.sheet>
              <.sheet_trigger target={"#{dom_id}-sheet"}>
                <.button variant="outline">Details</.button>
              </.sheet_trigger>
              <.sheet_content id={"#{dom_id}-sheet"} class="md:max-w-xl space-y-4">
                <.sheet_header>
                  <.sheet_title>
                    CSP Violation
                  </.sheet_title>
                  <.sheet_description>
                    <h2 class="text-sm font-medium text-zinc-500">Action</h2>
                    <.badge
                      variant={
                        if violation.disposition == :enforce, do: "destructive", else: "secondary"
                      }
                      class="self-start"
                    >
                      <%= violation.disposition %>
                    </.badge>
                    <h2 class="text-sm font-medium text-zinc-500">Time (UTC)</h2>
                    <div><%= violation.happened_at %></div>
                    <h2 class="text-sm font-medium text-zinc-500">IP Address</h2>
                    <div class="text-sm font-medium text-zinc-900">
                      <%= violation.remote_ip %>
                    </div>
                    <h2 class="text-sm font-medium text-zinc-500">User Agent</h2>
                    <div class="text-sm font-medium text-zinc-900">
                      <%= violation.user_agent %>
                    </div>
                  </.sheet_description>
                </.sheet_header>
                <.separator />
                <pre class="overflow-x-auto p-4 bg-zinc-100 rounded-md"><%= Jason.encode!(violation.raw, pretty: true) %></pre>
              </.sheet_content>
            </.sheet>
          </.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end
end
