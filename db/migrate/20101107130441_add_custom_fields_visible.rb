class AddCustomFieldsVisible < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :visible, :boolean, :null => false, :default => true
    CustomField.update_all("visible = #{CustomField.connection.quoted_true}")
  end

  def self.down
    remove_column :custom_fields, :visible
  end
end
