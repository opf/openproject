class AddOAuthClientIdSecretToStorages < ActiveRecord::Migration[6.1]
  def change
    add_column :storages, :oauth_client_id, :string
    add_column :storages, :oauth_client_secret, :string
  end
end
