defmodule DemoWeb.Live.Home.Index do
  @moduledoc false

  use DemoWeb, :live_view

  alias DemoWeb.Live.Classes
  alias DemoWeb.Live.Home.Components.AboutSection
  alias DemoWeb.Live.Home.Components.BuildInfo
  alias DemoWeb.Live.Home.Components.ComputationState
  alias DemoWeb.Live.Home.Components.DevShowAllValues
  alias DemoWeb.Live.Home.Components.DevShowFlowAnalyticsTable
  alias DemoWeb.Live.Home.Components.DevShowJourneyExecutionSummary
  alias DemoWeb.Live.Home.Components.DevShowOtherComputedValues
  alias DemoWeb.Live.Home.Components.DevShowRecentExecutions
  alias DemoWeb.Live.Home.Components.DevShowWorkflowGraph
  alias DemoWeb.Live.Home.Components.Dialogs.About
  alias DemoWeb.Live.Home.Components.Dialogs.ContactUs
  alias DemoWeb.Live.Home.Components.FlowAnalyticsJson
  alias DemoWeb.Live.Home.Components.Footer
  alias DemoWeb.Live.Home.Components.Gear

  require Logger

  @impl true
  def mount(%{"execution_id" => execution_id} = _params, _session, socket) do
    Logger.metadata(eid: execution_id)

    Logger.info("home.mount execution_id: #{execution_id}")

    socket =
      socket
      |> assign(:connected?, connected?(socket))
      |> assign(:show_contact_dialog, false)
      |> assign(:show_about_dialog, false)
      |> assign(:build_info, "")
      |> set_system_stats_if_needed()

    loaded_execution = Journey.load(execution_id)

    socket =
      if loaded_execution == nil do
        socket
        |> assign(:execution_id, nil)
        |> create_execution_if_needed()
      else
        Logger.info("Successfully loaded execution #{execution_id}")
        # Subscribe to PubSub for this execution
        :ok = Phoenix.PubSub.subscribe(Demo.PubSub, "execution:#{execution_id}")

        socket
        |> assign(:execution_id, execution_id)
        |> refresh_execution_state(loaded_execution)
      end

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    Logger.metadata(eid: "none")
    Logger.info("home.mount")

    socket =
      socket
      |> assign(:connected?, connected?(socket))
      |> set_system_stats_if_needed()
      |> assign(:show_contact_dialog, false)
      |> assign(:show_about_dialog, false)
      |> assign(:build_info, "")
      |> assign(:execution_id, nil)
      |> assign(:values, %{})
      |> assign(:all_values, %{})
      |> assign(:execution_summary, nil)
      |> assign(:computation_states, %{})
      |> assign(:execution_history, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    Logger.info("handle_params: params: #{inspect(params)}, uri: #{inspect(uri)}")
    {:noreply, socket}
  end

  @impl true
  def handle_event("on-dev-show-more-click", _params, socket) do
    current_value = Map.get(socket.assigns.values, :dev_show_more, false)
    new_value = !current_value

    socket = async_save_value(socket, :dev_show_more, new_value)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dev_toggle", params, socket) do
    field_name = Map.get(params, "toggle_field_name") |> String.to_existing_atom()
    bool_value = Map.get(params, "dev_toggle", "off") == "on"

    socket = async_save_value(socket, field_name, bool_value)
    {:noreply, socket}
  end

  @impl true
  def handle_event("chevron_toggle", params, socket) do
    field_name = Map.get(params, "toggle_field_name") |> String.to_existing_atom()
    current_value = Map.get(socket.assigns.values, field_name, false)
    bool_value = !current_value

    socket = async_save_value(socket, field_name, bool_value)
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_value", %{"field" => field, "value" => value}, socket) do
    Logger.info("update_value field: #{field} value: #{value}")

    field_atom = String.to_existing_atom(field)

    # Convert birth_day to integer if it's a number
    parsed_value =
      if field == "birth_day" and value != "" do
        case Integer.parse(value) do
          {num, ""} -> num
          _ -> value
        end
      else
        value
      end

    socket =
      if parsed_value == "" do
        async_save_value(socket, field_atom, nil, :unset)
      else
        async_save_value(socket, field_atom, parsed_value, :set)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_select", %{"field" => field} = params, socket) do
    # For select elements, the value comes as params[field]
    value = Map.get(params, field, "")
    Logger.info("update_select field: #{field} value: #{value}")

    field_atom = String.to_existing_atom(field)

    socket =
      if value == "" do
        async_save_value(socket, field_atom, nil, :unset)
      else
        async_save_value(socket, field_atom, value, :set)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("on-retry-computation-click", %{"node_name" => node_name}, socket) do
    Logger.info("Retry computation clicked for node: #{node_name}")

    updated_execution =
      Journey.Tools.retry_computation(
        socket.assigns.execution_id,
        String.to_existing_atom(node_name)
      )

    socket = refresh_execution_state(socket, updated_execution)
    {:noreply, socket}
  end

  @impl true
  def handle_event("on-feedback-emoji-frowney-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")

    new_feedback =
      Map.get(socket.assigns.values, :feedback_emoji, nil)
      |> case do
        nil ->
          "frowney"

        "frowney" ->
          nil

        "smiley" ->
          "frowney"

        _ ->
          "frowney"
      end

    socket =
      socket
      |> async_save_value(:feedback_emoji, new_feedback)

    {:noreply, socket}
  end

  @impl true
  def handle_event("on-feedback-emoji-smiley-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")

    new_feedback =
      Map.get(socket.assigns.values, :feedback_emoji, nil)
      |> case do
        nil ->
          "smiley"

        "smiley" ->
          nil

        "frowney" ->
          "smiley"

        _ ->
          "smiley"
      end

    socket =
      socket
      |> async_save_value(:feedback_emoji, new_feedback)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "on-feedback-text-change" = event,
        %{"feedback-text-field-name" => feedback_text} = _params,
        socket
      ) do
    Logger.info("handle_event[#{event}]")

    socket =
      socket
      |> async_save_value(:feedback_text, feedback_text)

    {:noreply, socket}
  end

  @impl true
  def handle_event("on-show-contact-us-dialog-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")

    socket =
      socket
      |> async_save_value(:contact_visited, true)
      |> assign(:show_contact_dialog, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("on-hide-contact-us-dialog-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")
    socket = socket |> assign(:show_contact_dialog, false)
    {:noreply, socket}
  end

  @impl true
  def handle_event("on-show-about-dialog-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")

    socket =
      socket
      |> async_save_value(:about_visited, true)
      |> assign(:show_about_dialog, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("on-hide-about-dialog-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")
    socket = socket |> assign(:show_about_dialog, false)
    {:noreply, socket}
  end

  @impl true
  def handle_event("on-build-info-click" = event, _params, socket) do
    Logger.info("handle_event[#{event}]")

    new_build_info =
      socket.assigns.build_info
      |> case do
        "" -> " for democracy"
        _ -> ""
      end

    socket =
      socket
      |> async_save_value(:build_info_checked, true)
      |> assign(:build_info, new_build_info)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:refresh, step_name, _value}, socket) do
    Logger.info(
      "handle_info[#{socket.assigns.execution_id}] Received refresh notification for step: #{step_name}"
    )

    # Reload the execution to get the latest values
    execution = Journey.load(socket.assigns.execution_id)

    socket =
      if execution == nil do
        Logger.warning(
          "handle_info[#{socket.assigns.execution_id}] Execution not found, skipping refresh"
        )

        socket
      else
        refresh_execution_state(socket, execution)
      end

    {:noreply, socket}
  end

  # Helper function to create execution if it doesn't exist
  defp create_execution_if_needed(socket) do
    if is_nil(socket.assigns.execution_id) do
      # Create new execution
      graph = Demo.HoroscopeGraph.graph()

      new_execution =
        Journey.start_execution(graph)
        |> Journey.set(:email_address, "me@example.com")

      # Subscribe to PubSub for updates
      :ok = Phoenix.PubSub.subscribe(Demo.PubSub, "execution:#{new_execution.id}")

      Logger.metadata(eid: new_execution.id)
      Logger.info("create_execution_if_needed: created a new execution #{new_execution.id}")

      socket
      |> assign(:execution_id, new_execution.id)
      |> refresh_execution_state(new_execution)
      |> push_patch(to: "/s/#{new_execution.id}")
    else
      # Execution already exists, do nothing
      socket
    end
  end

  defp set_system_stats_if_needed(socket) do
    # Get flow analytics if not already loaded
    graph = Demo.HoroscopeGraph.graph()

    flow_analytics =
      socket.assigns[:flow_analytics] ||
        Journey.Insights.FlowAnalytics.flow_analytics(graph.name, graph.version)

    # Generate Journey's text representation
    flow_analytics_text =
      socket.assigns[:flow_analytics_text] ||
        Journey.Insights.FlowAnalytics.to_text(flow_analytics)

    # Get graph mermaid if not already loaded
    graph_mermaid =
      socket.assigns[:graph_mermaid] ||
        Journey.Tools.generate_mermaid_graph(graph)

    socket
    |> assign(:flow_analytics, flow_analytics)
    |> assign(:flow_analytics_text, flow_analytics_text)
    |> assign(:graph_mermaid, graph_mermaid)
  end

  # Centralized function to refresh execution state in socket
  # Always refreshes all execution data for simplicity
  defp refresh_execution_state(socket, execution) do
    execution_history = Journey.history(execution.id) |> format_history()

    merged_values = Map.merge(socket.assigns[:values] || %{}, Journey.values(execution))

    socket
    |> assign(:values, merged_values)
    |> assign(:all_values, Journey.values_all(execution))
    |> assign(:execution_summary, Journey.Tools.introspect(execution.id))
    |> assign(:computation_states, get_computation_states(execution.id))
    |> assign(:execution_history, execution_history)
  end

  defp async_save_value(socket, value_name, value, set_or_unset \\ :set) do
    socket = socket |> create_execution_if_needed()

    execution_id = socket.assigns.execution_id

    Task.start(fn ->
      try do
        execution =
          case set_or_unset do
            :set -> Journey.set(execution_id, value_name, value)
            :unset -> Journey.unset(execution_id, value_name)
          end

        Logger.info(
          "async_save_value[#{execution_id}]: completed. saving value #{value_name} to #{value} #{inspect(set_or_unset)}. revision: #{execution.revision}"
        )
      rescue
        e ->
          Logger.warning(
            "async_save_value[#{execution_id}]: failed to save value #{value_name}: #{inspect(e)}"
          )
      end
    end)

    new_values =
      socket.assigns.values
      |> Map.put(value_name, value)

    socket
    |> assign(:values, new_values)
  end

  # Helper function to get computation states for all computed nodes
  defp get_computation_states(execution_id) do
    %{
      name_validation: Journey.Tools.computation_status_as_text(execution_id, :name_validation),
      zodiac_sign: Journey.Tools.computation_status_as_text(execution_id, :zodiac_sign),
      horoscope: Journey.Tools.computation_status_as_text(execution_id, :horoscope),
      anonymize_name: Journey.Tools.computation_status_as_text(execution_id, :anonymize_name),
      email_horoscope: Journey.Tools.computation_status_as_text(execution_id, :email_horoscope),
      weekly_reminder_schedule:
        Journey.Tools.computation_status_as_text(execution_id, :weekly_reminder_schedule),
      send_weekly_reminder:
        Journey.Tools.computation_status_as_text(execution_id, :send_weekly_reminder),
      schedule_archive: Journey.Tools.computation_status_as_text(execution_id, :schedule_archive),
      auto_archive: Journey.Tools.computation_status_as_text(execution_id, :auto_archive)
    }
  end

  # Helper function to format timestamp fields
  def format_timestamp(nil), do: "not set"

  def format_timestamp(unix_timestamp) when is_integer(unix_timestamp) do
    DateTime.from_unix!(unix_timestamp)
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end

  def format_timestamp(_), do: "not set"

  # Helper function to format Journey.Executions.history output into human-friendly strings
  def format_history(nil), do: []

  def format_history(history_entries) when is_list(history_entries) do
    history_entries
    |> Enum.reverse()
    |> Enum.reduce([], fn entry, acc ->
      case entry do
        %{
          computation_or_value: :computation,
          node_name: node_name,
          node_type: node_type,
          revision: revision
        } ->
          acc ++ [{revision, "computation `#{node_name}` (#{inspect(node_type)}) completed"}]

        %{
          computation_or_value: :value,
          node_name: node_name,
          value: value,
          revision: revision
        } ->
          formatted_value = format_history_value(value)
          acc ++ [{revision, "value `#{node_name}` was set (#{formatted_value})"}]

        _ ->
          Logger.warning("format_history: unexpected entry: #{inspect(entry)}")
          acc
      end
    end)
  end

  defp format_history_value(value) when is_binary(value), do: inspect(value)
  defp format_history_value(value) when is_integer(value), do: value
  defp format_history_value(value) when is_atom(value), do: inspect(value)
  defp format_history_value(value), do: inspect(value)

  defp downcase(nil), do: nil
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
