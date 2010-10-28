class CreateGlobalRole < ActiveRecord::Migration
  def self.up
    create_table :global_roles, :force => true do |t|
      t.column :name, :string, :limit => 30, :default => "",:null => false
      t.column :permissions, :text
      t.column :position, :integer, :default => 1
      t.timestamps
    end

    create_table :principal_global_roles, :force => true do |t|
      t.column :global_role_id, :integer, :null => false
      t.column :principal_id, :integer, :null => false
      t.timestamps
    end

    add_index :principal_global_roles, :global_role_id
    add_index :principal_global_roles, :principal_id
  end

  def self.down
    remove_index :principal_global_roles, :user_id
    remove_index :principal_global_roles, :column_name
    drop_table :principal_roles
    drop_table :global_roles
  end
end
