class CreateDoorkeeperTables < ActiveRecord::Migration[5.1]
  def change
    create_table :oauth_applications do |t|
      t.string  :name,         null: false
      t.string  :uid,          null: false
      t.string  :secret,       null: false
      t.string  :owner_type
      t.integer :owner_id
      t.integer :client_credentials_user_id
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    # Add owner of an application
    add_foreign_key :oauth_applications, :users, column: :owner_id, on_delete: :nullify

    # Allow to map a user to use for client credentials auth flow
    add_foreign_key :oauth_applications, :users, column: :client_credentials_user_id, on_delete: :nullify

    add_index :oauth_applications, :uid, unique: true
    add_index :oauth_applications, %i[owner_id owner_type]

    create_table :oauth_access_grants do |t|
      t.references :resource_owner,  null: false
      t.references :application,     null: false
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
      t.string   :scopes
    end

    add_index :oauth_access_grants, :token, unique: true
    add_foreign_key(
      :oauth_access_grants,
      :oauth_applications,
      column: :application_id
    )

    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, index: true
      t.references :application

      # If you use a custom token generator you may need to change this column
      # from string to text, so that it accepts tokens larger than 255
      # characters. More info on custom token generators in:
      # https://github.com/doorkeeper-gem/doorkeeper/tree/v3.0.0.rc1#custom-access-token-generator
      #
      # t.text     :token,             null: false
      t.string   :token,                  null: false

      t.string   :refresh_token
      t.integer  :expires_in
      t.datetime :revoked_at
      t.datetime :created_at,             null: false
      t.string   :scopes

      # If there is a previous_refresh_token column,
      # refresh tokens will be revoked after a related access token is used.
      # If there is no previous_refresh_token column,
      # previous tokens are revoked as soon as a new access token is created.
      # Comment out this line if you'd rather have refresh tokens
      # instantly revoked.
      t.string   :previous_refresh_token, null: false, default: ""
    end

    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
    add_foreign_key(
      :oauth_access_tokens,
      :oauth_applications,
      column: :application_id
    )

    # Add PKCE challenges column
    add_column :oauth_access_grants, :code_challenge, :string, null: true
    add_column :oauth_access_grants, :code_challenge_method, :string, null: true
  end
end
