class AddCustomFieldsPosition < ActiveRecord::Migration
  def self.up
    add_column(:custom_fields, :position, :integer, :default => 1)
    CustomField.find(:all).group_by(&:type).each_value  do |fields|
      fields.each_with_index do |field, i|
        # do not call model callbacks
        CustomField.update_all "position = #{i+1}", {:id => field.id}
      end
    end
  end

  def self.down
    remove_column :custom_fields, :position
  end
end
