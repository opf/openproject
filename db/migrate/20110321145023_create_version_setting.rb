class CreateVersionSetting < ActiveRecord::Migration
  def self.up
    create_table :version_settings, :force => true do |t|
      t.integer :project_id
      t.integer :version_id
      t.integer :display
      t.timestamps
    end

    add_index :version_settings, [:project_id, :version_id]
  end

  def self.down
    remove_index :version_settings, [:project_id, :version_id]
    drop_table :table_name
  end
end