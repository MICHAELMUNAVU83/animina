defmodule Animina.Repo.Migrations.AddTagSystem do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:traits_flags, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :name, :citext, null: false
      add :category_id, :uuid
    end

    create table(:traits_flag_translations, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :language, :text, null: false
      add :name, :citext, null: false
      add :hashtag, :citext, null: false

      add :flag_id,
          references(:traits_flags,
            column: :id,
            name: "traits_flag_translations_flag_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    create unique_index(:traits_flag_translations, [:hashtag, :language],
             name: "traits_flag_translations_hashtag_index"
           )

    create unique_index(:traits_flag_translations, [:name, :language, :flag_id],
             name: "traits_flag_translations_unique_name_index"
           )

    create table(:traits_category_translations, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
      add :language, :text, null: false
      add :name, :citext, null: false
      add :category_id, :uuid
    end

    create table(:traits_categories, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
    end

    alter table(:traits_flags) do
      modify :category_id,
             references(:traits_categories,
               column: :id,
               name: "traits_flags_category_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create unique_index(:traits_flags, [:name, :category_id],
             name: "traits_flags_unique_name_index"
           )

    alter table(:traits_category_translations) do
      modify :category_id,
             references(:traits_categories,
               column: :id,
               name: "traits_category_translations_category_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:traits_categories) do
      add :name, :citext, null: false
    end

    create unique_index(:traits_categories, [:name], name: "traits_categories_unique_name_index")
  end

  def down do
    drop_if_exists unique_index(:traits_categories, [:name],
                     name: "traits_categories_unique_name_index"
                   )

    alter table(:traits_categories) do
      remove :name
    end

    drop constraint(
           :traits_category_translations,
           "traits_category_translations_category_id_fkey"
         )

    alter table(:traits_category_translations) do
      modify :category_id, :uuid
    end

    drop_if_exists unique_index(:traits_flags, [:name, :category_id],
                     name: "traits_flags_unique_name_index"
                   )

    drop constraint(:traits_flags, "traits_flags_category_id_fkey")

    alter table(:traits_flags) do
      modify :category_id, :uuid
    end

    drop table(:traits_categories)

    drop table(:traits_category_translations)

    drop_if_exists unique_index(:traits_flag_translations, [:name, :language, :flag_id],
                     name: "traits_flag_translations_unique_name_index"
                   )

    drop_if_exists unique_index(:traits_flag_translations, [:hashtag, :language],
                     name: "traits_flag_translations_hashtag_index"
                   )

    drop constraint(:traits_flag_translations, "traits_flag_translations_flag_id_fkey")

    drop table(:traits_flag_translations)

    drop table(:traits_flags)
  end
end