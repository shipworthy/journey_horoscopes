defmodule DemoWeb.Live.Home.Components.BuildInfo do
  @moduledoc false

  use DemoWeb, :html

  def render(assigns) do
    ~H"""
    <div class="w-full flex flex-col text-gray-600 items-center justify-center">
      <div class="text-sm py-1">
        Built with <span id="build-info-id" phx-click="on-build-info-click">❤️ {@build_info}</span>
        in Seattle, WA.
      </div>
    </div>
    """
  end
end
