class AddCustomFieldIsFilter < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :is_filter, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :custom_fields, :is_filter
  end
end
