class RemoveNotNullConstraintForStorageHost < ActiveRecord::Migration[7.0]
  def up
    change_column :storages, :host, :string, null: true
    change_column :oauth_clients, :client_secret, :string, null: true
  end

  def down
    ::Storages::Storage.where(host: nil).delete_all
    change_column :storages, :host, :string, null: false

    ::OAuthClient.where(client_secret: nil).delete_all
    change_column :oauth_clients, :client_secret, :string, null: false
  end
end
