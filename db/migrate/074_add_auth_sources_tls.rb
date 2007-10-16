class AddAuthSourcesTls < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :tls, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :auth_sources, :tls
  end
end
