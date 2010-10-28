class StiForRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :type, :string, :limit => 30, :default => "Role"

    create_table :principal_roles, :force => true do |t|
      t.column :role_id, :integer, :null => false
      t.column :principal_id, :integer, :null => false
      t.timestamps
    end

    add_index :principal_roles, :role_id
    add_index :principal_roles, :principal_id
  end

  def self.down
    remove_column :roles, :type
    remove_index :principal_roles, :role_id
    remove_index :principal_roles, :principal_id
    drop_table :principal_roles
  end
end