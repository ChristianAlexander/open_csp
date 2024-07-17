defmodule OpenCspWeb.Components.Pagination do
  @moduledoc false
  use SaladUI, :component

  import OpenCspWeb.CoreComponents, only: [icon: 1]

  @doc """
  Render live button
  """
  attr(:"is-active", :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def pagination_live(assigns) do
    is_active = assigns[:"is-active"]

    ~H"""
    <SaladUI.Pagination.pagination_link
      size="default"
      class={classes(["space-x-2 px-2.5", @class])}
      is-active={is_active}
      {@rest}
    >
      <.icon :if={is_active} name="hero-play-solid" class="h-4 w-4 text-green-400" /><span>Live</span>
    </SaladUI.Pagination.pagination_link>
    """
  end
end
