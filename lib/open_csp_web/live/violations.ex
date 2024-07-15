defmodule OpenCspWeb.Live.Violations do
  use OpenCspWeb, :live_view

  alias OpenCsp.Reporting

  import SaladUI.Badge
  import SaladUI.Table

  @page_limit 100

  def mount(_params, _session, socket) do
    violations =
      Reporting.list_csp_violations(%{
        limit: @page_limit,
        sort_by: :happened_at,
        sort_order: :desc
      })

    if connected?(socket) do
      Phoenix.PubSub.subscribe(OpenCsp.PubSub, "violations:all")
    end

    socket =
      socket
      |> stream(:violations, violations, at: 0, limit: @page_limit)

    {:ok, socket}
  end

  def handle_info({:new_violation, violation}, socket) do
    {:noreply, stream_insert(socket, :violations, violation, at: 0, limit: @page_limit)}
  end

  def render(assigns) do
    ~H"""
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
