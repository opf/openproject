class CreateOAuthClientTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :oauth_client_tokens do |t|
      t.references :oauth_client, null: false, foreign_key: { to_table: :oauth_clients, on_delete: :cascade }
      t.references :user, null: false, index: true, foreign_key: { to_table: :users, on_delete: :cascade }

      t.string :access_token
      t.string :refresh_token
      t.string :token_type
      t.integer :expires_in
      t.string :scope
      t.string :origin_user_id # ID of the current user on the _OAuth2_provider_side_

      t.timestamps
      t.index %i[user_id oauth_client_id], unique: true
    end
  end
end
