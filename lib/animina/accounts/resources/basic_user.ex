defmodule Animina.Accounts.BasicUser do
  @moduledoc """
  This is the Basic User module. It is a stripped down version of the
  User module. It is used for the registration form.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true

    attribute :username, :ci_string do
      constraints max_length: 15,
                  min_length: 2,
                  match: ~r/^[A-Za-z_-]*$/,
                  trim?: true,
                  allow_empty?: false
    end

    attribute :name, :string do
      constraints max_length: 50,
                  min_length: 1,
                  trim?: true,
                  allow_empty?: false
    end

    attribute :birthday, :date, allow_nil?: false
    attribute :zip_code, :string, allow_nil?: false
    attribute :gender, :string, allow_nil?: false
    attribute :height, :integer, allow_nil?: false
    attribute :mobile_phone, :string, allow_nil?: false
  end

  calculations do
    calculate :gravatar_hash, :string, {Animina.Calculations.Md5, field: :email}
  end

  preparations do
    prepare build(load: [:gravatar_hash])
  end

  authentication do
    api Animina.Accounts

    strategies do
      password :password do
        identity_field :email
        sign_in_tokens_enabled? true
        confirmation_required?(false)

        register_action_accept([
          :username,
          :name,
          :zip_code,
          :birthday,
          :height,
          :gender,
          :mobile_phone
        ])
      end
    end

    tokens do
      enabled? true
      token_resource Animina.Accounts.Token

      signing_secret Animina.Accounts.Secrets
    end
  end

  postgres do
    table "users"
    repo Animina.Repo
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_username, [:username]
  end

  actions do
    defaults [:create, :read]
  end

  code_interface do
    define_for Animina.Accounts
    define :read
    define :create
    define :by_id, get_by: [:id], action: :read
  end
end
