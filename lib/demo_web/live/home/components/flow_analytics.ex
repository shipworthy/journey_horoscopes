defmodule DemoWeb.Live.Home.Components.FlowAnalytics do
  @moduledoc false

  use Phoenix.Component
  alias DemoWeb.Live.Classes

  attr :flow_analytics, :map, required: true
  attr :flow_analytics_text, :string, default: nil

  def render(assigns) do
    ~H"""
    <div id="flow-analytics-table" class="mt-2 p-4 bg-white border rounded">
      <div class="space-y-4">
        <!-- Journey Text Representation -->
        <div :if={@flow_analytics_text}>
          <h4 class="font-semibold text-md mb-2">Journey Text Output</h4>
          <pre class={Classes.debug_pre()}><%= "iex> g = Demo.HoroscopeGraph.graph()\niex> Journey.Insights.FlowAnalytics.flow_analytics(g.name, g.version) |> Journey.Insights.FlowAnalytics.to_text()\n\n#{@flow_analytics_text}" %></pre>
        </div>

        <!-- Overview Stats -->
        <div class="bg-gray-50 p-3 rounded">
          <h4 class="font-semibold text-md mb-2">
            Overview: {@flow_analytics.graph_name} ({@flow_analytics.graph_version})
          </h4>
          <div class="grid grid-cols-3 gap-4 text-md">
            <div>
              <span class="text-gray-600">Total Executions:</span>
              <span class="font-medium ml-1">{@flow_analytics.executions.count}</span>
            </div>
            <div>
              <span class="text-gray-600">Avg Duration:</span>
              <span class="font-medium ml-1">
                <%= if avg = @flow_analytics.executions.duration_avg_seconds_to_last_update do %>
                  {cond do
                    avg < 60 ->
                      "#{round(avg)}s"

                    avg < 3600 ->
                      minutes = div(round(avg), 60)
                      secs = rem(round(avg), 60)
                      if secs > 0, do: "#{minutes}m #{secs}s", else: "#{minutes}m"

                    true ->
                      hours = div(round(avg), 3600)
                      minutes = div(rem(round(avg), 3600), 60)
                      if minutes > 0, do: "#{hours}h #{minutes}m", else: "#{hours}h"
                  end}
                <% else %>
                  N/A
                <% end %>
              </span>
            </div>
            <div>
              <span class="text-gray-600">Median Duration:</span>
              <span class="font-medium ml-1">
                <%= if median = @flow_analytics.executions.duration_median_seconds_to_last_update do %>
                  {cond do
                    median < 60 ->
                      "#{round(median)}s"

                    median < 3600 ->
                      minutes = div(round(median), 60)
                      secs = rem(round(median), 60)
                      if secs > 0, do: "#{minutes}m #{secs}s", else: "#{minutes}m"

                    true ->
                      hours = div(round(median), 3600)
                      minutes = div(rem(round(median), 3600), 60)
                      if minutes > 0, do: "#{hours}h #{minutes}m", else: "#{hours}h"
                  end}
                <% else %>
                  N/A
                <% end %>
              </span>
            </div>
          </div>
        </div>

        <!-- Node Statistics Table -->
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b text-left">
              <th class="pb-2">Node</th>
              <th class="pb-2">Type</th>
              <th class="pb-2 text-right">Reached</th>
              <th class="pb-2 text-right">Avg Time</th>
              <th class="pb-2 text-right">Drop-off</th>
            </tr>
          </thead>
          <tbody>
            <%= for node <- (@flow_analytics.node_stats.nodes || []) |> Enum.sort_by(& &1.average_time_to_reach) do %>
              <tr class={
                if node.reached_percentage < 100, do: "border-b bg-yellow-50", else: "border-b"
              }>
                <td class="py-2 font-medium">{node.node_name}</td>
                <td class="py-2 text-gray-600">{node.node_type}</td>
                <td class="py-2 text-right">
                  {node.reached_count}/{@flow_analytics.executions.count} ({Float.round(
                    node.reached_percentage,
                    1
                  )}%)
                </td>
                <td class="py-2 text-right">
                  {time = node.average_time_to_reach

                  cond do
                    time < 60 ->
                      "#{round(time)}s"

                    time < 3600 ->
                      minutes = div(round(time), 60)
                      secs = rem(round(time), 60)
                      if secs > 0, do: "#{minutes}m #{secs}s", else: "#{minutes}m"

                    true ->
                      hours = div(round(time), 3600)
                      minutes = div(rem(round(time), 3600), 60)
                      if minutes > 0, do: "#{hours}h #{minutes}m", else: "#{hours}h"
                  end}
                </td>
                <td class={
                    "py-2 text-right " <>
                    if node.flow_ends_here_percentage_of_all > 0 do
                      "text-orange-600"
                    else
                      "text-green-600"
                    end
                  }>
                  {Float.round(node.flow_ends_here_percentage_of_all, 1)}%
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
