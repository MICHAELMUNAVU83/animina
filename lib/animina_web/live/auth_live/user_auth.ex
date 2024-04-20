defmodule AniminaWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in liveviews
  """

  alias Animina.Accounts.Credit
  alias Animina.Accounts.User
  alias AniminaWeb.Registration
  import Phoenix.Component

  use AniminaWeb, :verified_routes

  def on_mount(:live_user_optional, _params, session, socket) do
    if socket.assigns[:current_user] do
      current_user = Registration.get_current_user(session)

      {:cont,
       socket
       |> assign(:current_user, current_user)
       |> assign(:current_user_credit_points, current_user.credit_points)}
    else
      {:cont,
       socket
       |> assign(:current_user_credit_points, 0)
       |> assign(:current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, session, socket) do
    path =
      case Map.get(socket.private.connect_info, :request_path, nil) do
        nil ->
          "sign-in"

        path ->
          case Map.get(socket.private.connect_info, :query_string, nil) do
            nil ->
              "sign-in?redirect_to=" <> path

            "" ->
              "sign-in?redirect_to=" <> path

            query_string ->
              "sign-in?redirect_to=" <> path <> "?" <> query_string
          end
      end

    if socket.assigns[:current_user] do
      current_user =
        Registration.get_current_user(session)

      add_daily_points_for_user(
        current_user,
        100,
        check_if_user_has_daily_bonus_added_for_the_day(current_user.id)
      )

      {:cont,
       socket
       |> assign(:current_user, current_user)
       |> assign(:current_user_credit_points, current_user.credit_points)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/#{path}")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    else
      {:cont,
       socket
       |> assign(:current_user_credit_points, 0)
       |> assign(:current_user, nil)}
    end
  end

  def check_if_user_has_daily_bonus_added_for_the_day(user_id) do
    {:ok, credits} = Credit.read()

    credits
    |> Enum.filter(fn credit ->
      credit.user_id == user_id and
        format_date(credit.created_at) == format_date(DateTime.utc_now()) and
        credit.subject == "Daily Bonus"
    end)
    |> List.first()
  end

  defp format_date(date) do
    {:ok, date} = Timex.format(date, "{YYYY}-{0M}-{0D}")
    date
  end

  # in this case the user does not have a daily bonus added for the day , so we add one
  defp add_daily_points_for_user(user, points, nil) do
    Credit.create(%{
      user_id: user.id,
      points: points,
      subject: "Daily Bonus"
    })

    update_streak_depending_on_whether_used_the_system_a_day_before(user)

    # we then check if a user has been using has a streak of 10 days
    # we add 150 extra points so that they can have a total of 250 points

    if is_multiple_of_ten(user.streak) do
      Credit.create(%{
        user_id: user.id,
        points: 150,
        subject: "Daily Bonus"
      })
    end
  end

  def is_multiple_of_ten(streak) when is_integer(streak) do
    rem(streak, 10) == 0
  end

  defp add_daily_points_for_user(_user, _points, _) do
  end

  def current_day do
    Timex.now()
  end

  def previous_day do
    Timex.shift(Timex.now(), days: -1)
  end

  def daily_bonus_credits_for_a_user(user_id) do
    {:ok, credits} = Credit.read()

    credits
    |> Enum.filter(fn credit ->
      credit.user_id == user_id and credit.subject == "Daily Bonus"
    end)
  end

  def update_streak_depending_on_whether_used_the_system_a_day_before(user) do
    daily_bonus_credits =
      daily_bonus_credits_for_a_user(user.id)
      |> Enum.filter(fn credit ->
        format_date(credit.created_at) == format_date(previous_day())
      end)

    # if a user used the system before , we add the streak and if they did not , we reset it to 1

    if Enum.count(daily_bonus_credits) > 0 do
      {:ok, _user} = User.update(user, %{streak: user.streak + 1})
    else
      {:ok, _user} = User.update(user, %{streak: 1})
    end
  end
end
