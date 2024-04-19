defmodule Animina.Repo.Migrations.AddStreakToUsers do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      add :streak, :integer, null: false, default: 0
    end
  end

  def down do
    alter table(:users) do
      remove :streak
    end
  end
end
