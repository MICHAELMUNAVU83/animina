defmodule Animina.GenServers.ProfileViewCredits do
  use GenServer
  alias Phoenix.PubSub

  @moduledoc """
  This is the genserver that handles the credits added for the profile view
  """

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    PubSub.subscribe(Animina.PubSub, "credits")
    schedule_credits_update()
    {:ok, state}
  end

  @impl true
  def handle_info(:credits_update, state) do
    schedule_credits_update()

    PubSub.broadcast(Animina.PubSub, "credits", {:display_updated_credits, state})

    {:noreply, state}
  end

  def handle_info({:credit_updated, updated_credit}, state) do
    {:noreply, update_array(state, updated_credit)}
  end

  def handle_info({:display_updated_credits, _updated_credit}, state) do
    {:noreply, state}
  end

  defp schedule_credits_update do
    Process.send_after(self(), :credits_update, 2_000)
  end

  def update_array(state, map) do
    case Enum.find(state, fn x -> x["user_id"] == map["user_id"] end) do
      nil ->
        state ++ [map]

      _ ->
        Enum.drop_while(state, fn x -> x["user_id"] == map["user_id"] end)
        |> List.insert_at(0, map)
    end
  end

  def get_updated_credit_for_user(socket, credits) do
    case Enum.find(credits, fn credit ->
           credit["user_id"] == socket.assigns.current_user.id
         end) do
      nil -> socket.assigns.current_user.credit_points
      credit -> credit["points"]
    end
  end

  def get_updated_credit_for_profile(profile, credits) do
    case Enum.find(credits, fn credit ->
           credit["user_id"] == profile.credit_points
         end) do
      nil -> profile.credit_points
      credit -> credit["points"]
    end
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def get_updated_credits do
    GenServer.call(__MODULE__, :get)
  end
end
