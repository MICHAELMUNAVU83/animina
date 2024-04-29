defmodule Animina.Repo.Migrations.MigrateResources13 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      add :last_registration_page_visited, :text
    end
  end

  def down do
    alter table(:users) do
      remove :last_registration_page_visited
    end
  end

end
