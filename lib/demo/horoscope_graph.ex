defmodule Demo.HoroscopeGraph do
  @moduledoc """
  Journey graph for the horoscope demo application.

  This demonstrates Journey's key features:
  - Input validation and conditional flow
  - Automatic computation when dependencies are satisfied
  - Data mutation for privacy
  - Scheduled one-time and recurring events
  - Clean separation of workflow and business logic
  """

  import Journey.Node
  import Journey.Node.UpstreamDependencies
  import Journey.Node.Conditions

  require Logger

  # Helper function to notify LiveView of updates
  defp notify(execution_id, step, data) do
    Logger.info("Journey notify: execution_id: #{execution_id}, step: #{step}")
    Phoenix.PubSub.broadcast(Demo.PubSub, "execution:#{execution_id}", {:refresh, step, data})
    :ok
  end

  def graph() do
    Journey.new_graph(
      "Horoscope Demo App",
      "v1.0.1",
      [
        # === Input Nodes ===
        input(:name),
        input(:birth_day),
        input(:birth_month),
        input(:pet_preference),
        input(:email_address),
        input(:subscribe_weekly),

        # === Name Validation (Conditional Flow) ===
        compute(
          :name_validation,
          [:name],
          &keep_bowser_out/1
        ),

        # === Zodiac Computation ===
        compute(
          :zodiac_sign,
          unblocked_when({
            :and,
            [
              {:birth_month, &provided?/1},
              {:birth_day, &provided?/1},
              {:name_validation, &name_is_valid?/1}
            ]
          }),
          &compute_zodiac_sign/1
        ),

        # === Horoscope Generation ===
        compute(
          :horoscope,
          [:zodiac_sign, :pet_preference, :name],
          &generate_horoscope/1
        ),

        # === Data Mutation (Privacy) ===
        mutate(
          :anonymize_name,
          # Only anonymize after validation passes
          [:name_validation],
          &anonymize_name_value/1,
          mutates: :name
        ),

        # === Email Horoscope ===
        compute(
          :email_horoscope,
          [:horoscope, :email_address, :name],
          &send_horoscope_email/1
        ),

        # === Weekly Reminder Scheduling ===
        tick_recurring(
          :weekly_reminder_schedule,
          unblocked_when({
            :and,
            [
              {:subscribe_weekly, &true?/1},
              {:horoscope, &provided?/1}
            ]
          }),
          &schedule_weekly_reminders/1
        ),

        # === Send Weekly Reminder ===
        compute(
          :send_weekly_reminder,
          unblocked_when({
            :and,
            [
              {:subscribe_weekly, &true?/1},
              {:weekly_reminder_schedule, &provided?/1},
              {:email_address, &provided?/1}
            ]
          }),
          # [:weekly_reminder_schedule, :email_address, :name],
          &send_weekly_reminder_email/1
        ),

        # === Auto-archive after 2 weeks of inactivity ===
        tick_once(
          :schedule_archive,
          [:horoscope],
          &schedule_archive_time/1
        ),
        archive(
          :auto_archive,
          [:schedule_archive]
        ),
        input(:dev_show_execution_history),
        input(:dev_show_computation_states),
        input(:show_all_computations),
        input(:dev_show_all_values),
        input(:dev_show_recent_executions),
        input(:dev_show_journey_execution_summary),
        input(:dev_show_flow_analytics_table),
        input(:dev_show_flow_analytics_json),
        input(:dev_show_workflow_graph),
        input(:dev_show_other_computed_values),
        input(:dev_show_more),
        input(:feedback_emoji),
        input(:feedback_text),
        input(:contact_visited),
        input(:about_visited),
        input(:build_info_checked)
      ],
      f_on_save: fn execution_id, node_name, result ->
        notify(execution_id, node_name, result)
      end
    )
  end

  defp name_is_valid?(validation_node) do
    validation_node.node_value == "not bowser"
  end

  # === Business Logic Functions ===
  # These are placeholders demonstrating where real business logic would go

  def keep_bowser_out(%{name: name}) do
    # In production, this might check against a database of blocked names,
    # validate name format, check for profanity, etc.
    case String.downcase(String.trim(name)) do
      "bowser" ->
        {:ok, "no horoscope for Bowser!"}

      _ ->
        {:ok, "not bowser"}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def compute_zodiac_sign(%{birth_month: month, birth_day: day}) do
    Logger.info("Journey compute_zodiac_sign called: month=#{month}, day=#{day}")
    # In production, this would use a proper astrological calculation
    # or API service for accurate zodiac determination
    sign =
      case {String.downcase(month), day} do
        {"january", d} when d >= 20 -> "Aquarius"
        {"january", _} -> "Capricorn"
        {"february", d} when d >= 19 -> "Pisces"
        {"february", _} -> "Aquarius"
        {"march", d} when d >= 21 -> "Aries"
        {"march", _} -> "Pisces"
        {"april", d} when d >= 20 -> "Taurus"
        {"april", _} -> "Aries"
        {"may", d} when d >= 21 -> "Gemini"
        {"may", _} -> "Taurus"
        {"june", d} when d >= 21 -> "Cancer"
        {"june", _} -> "Gemini"
        {"july", d} when d >= 23 -> "Leo"
        {"july", _} -> "Cancer"
        {"august", d} when d >= 23 -> "Virgo"
        {"august", _} -> "Leo"
        {"september", d} when d >= 23 -> "Libra"
        {"september", _} -> "Virgo"
        {"october", d} when d >= 23 -> "Scorpio"
        {"october", _} -> "Libra"
        {"november", d} when d >= 22 -> "Sagittarius"
        {"november", _} -> "Scorpio"
        {"december", d} when d >= 22 -> "Capricorn"
        {"december", _} -> "Sagittarius"
        # Default fallback
        _ -> "Taurus"
      end

    {:ok, sign}
  end

  def generate_horoscope(%{zodiac_sign: sign, pet_preference: pet_pref, name: name}) do
    # In production, this would call an LLM API like OpenAI GPT-4
    # with a prompt combining the user's zodiac sign and preferences
    base_horoscope = get_base_horoscope(sign)
    pet_modifier = get_pet_modifier(pet_pref)

    horoscope =
      """
      #{base_horoscope}
      #{pet_modifier}
      Computed with Journey, for #{String.first(name)}****.
      """

    {:ok, horoscope}
  end

  def send_horoscope_email(%{horoscope: _horoscope, email_address: email, name: name} = values) do
    # In production, this would integrate with SendGrid, Mailgun, AWS SES, etc.
    # and send an actual email with the horoscope content
    # Simulate API call delay
    Process.sleep(500)

    dev_mode? = Map.get(values, :dev_show_more, false)

    # In the dev mode, simulate occasional API failures.
    if dev_mode? and :rand.uniform(100) <= 10 do
      {:error, "Email service temporarily unavailable. Mercury must be in microwave mode."}
    else
      {:ok, "Horoscope successfully sent to #{name} at #{email}. (but not really;)"}
    end
  end

  def schedule_weekly_reminders(_values) do
    # In production, this might check user timezone, optimal send times, etc.
    next_week = System.system_time(:second) + 7 * 24 * 60 * 60
    {:ok, next_week}
  end

  def send_weekly_reminder_email(%{email_address: email, name: name}) do
    # In production, this would send a personalized weekly horoscope update
    # Simulate API call
    Process.sleep(200)
    {:ok, "Weekly cosmic update sent to #{email} for #{name}!"}
  end

  def anonymize_name_value(%{name: name}) do
    case String.length(name) do
      0 ->
        {:ok, ""}

      len ->
        len = max(len, 2)
        first_char = String.first(name)
        asterisks = String.duplicate("*", len - 1)
        {:ok, first_char <> asterisks}
    end
  end

  def schedule_archive_time(_values) do
    # Archive execution 2 weeks after completion
    two_weeks = System.system_time(:second) + 14 * 24 * 60 * 60
    {:ok, two_weeks}
  end

  # === Helper Functions ===

  defp get_base_horoscope(sign) do
    # Hardcoded funny horoscopes for demo purposes
    horoscopes = %{
      "Aries" => "Tomorrow, someone will think of you and smile.",
      "Taurus" => "The stars suggest treating yourself to a lovely meal and/or a walk.",
      "Gemini" => "This is a great week to write your promises on stickies.",
      "Cancer" => "An old friend is wondering how you are, would love to hear from you.",
      "Leo" => "Something delightful will happen this week. Keep your eyes open.",
      "Virgo" => "Someone will be thinking of you fondly.",
      "Libra" => "This week you will make some great choices.",
      "Scorpio" => "The cashier who rang you up thought you were delightful.",
      "Sagittarius" => "This week, you and your word will become closer friends.",
      "Capricorn" => "This week, you will choose something that you will then love.",
      "Aquarius" =>
        "There is a grateful houseplant out there that would not exist if not for you.",
      "Pisces" => "This is a good week to be home, wherever you actually are."
    }

    Map.get(horoscopes, sign, "The universe is delighted you are here.")
  end

  defp get_pet_modifier(preference) do
    case preference do
      "cats" ->
        "A curious kitty will side-glance at you approvingly."

      "dogs" ->
        "There are 8 dogs in your vicinity that would like to play with you."

      "both" ->
        "Dogs are happy that you exist. Cats, too, but they don't care to admit it."

      "neither" ->
        "Dogs have questions. Cats are too busy to care. Houseplants are excited."

      _ ->
        "The universe likes your unique perspective on pets."
    end
  end
end
