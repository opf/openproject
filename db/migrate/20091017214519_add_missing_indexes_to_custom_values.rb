class AddMissingIndexesToCustomValues < ActiveRecord::Migration
  def self.up
    add_index :custom_values, :custom_field_id
  end

  def self.down
    remove_index :custom_values, :custom_field_id
  end
end
