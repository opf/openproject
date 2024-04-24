class SetCustomFieldsFilterDefaultTrue < ActiveRecord::Migration[7.0]
  def up
    change_column_default :custom_fields, :is_filter, true
  end

  def down
    change_column_default :custom_fields, :is_filter, false
  end
end
