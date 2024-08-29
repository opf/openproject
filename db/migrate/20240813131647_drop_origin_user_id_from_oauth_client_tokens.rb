class DropOriginUserIdFromOAuthClientTokens < ActiveRecord::Migration[7.1]
  def change
    remove_column :oauth_client_tokens, :origin_user_id, :string
  end
end
