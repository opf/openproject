class SetCustomFieldsEditable < ActiveRecord::Migration
  def self.up
    UserCustomField.update_all('editable = false')
  end

  def self.down
    UserCustomField.update_all('editable = true')
  end
end
