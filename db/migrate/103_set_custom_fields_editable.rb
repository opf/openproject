class SetCustomFieldsEditable < ActiveRecord::Migration
  def self.up
    UserCustomField.update_all("editable = #{CustomField.connection.quoted_false}")
  end

  def self.down
    UserCustomField.update_all("editable = #{CustomField.connection.quoted_true}")
  end
end
