class AddCustomFieldsEditable < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :editable, :boolean, :default => true
  end

  def self.down
    remove_column :custom_fields, :editable
  end
end
