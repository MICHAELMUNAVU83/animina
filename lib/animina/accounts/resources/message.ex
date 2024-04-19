defmodule Animina.Accounts.Message do
  @moduledoc """
  This is the Message module which we use to manage messages between users.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      constraints max_length: 1_024
    end

    attribute :read_at, :utc_datetime_usec do
      allow_nil? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :sender, Animina.Accounts.User do
      api Animina.Accounts
      attribute_writable? true
    end

    belongs_to :receiver, Animina.Accounts.User do
      api Animina.Accounts
      attribute_writable? true
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for Animina.Accounts
    define :read
    define :create
    define :update
    define :destroy
  end

  postgres do
    table "messages"
    repo Animina.Repo
  end
end
