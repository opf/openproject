class AddCustomFieldsSearchable < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :searchable, :boolean, :default => false
  end

  def self.down
    remove_column :custom_fields, :searchable
  end
end
