class ExtendCustomFieldNameLength < ActiveRecord::Migration[6.1]
  def up
    change_column :custom_fields, :name, :string, limit: nil
  end

  def down
    change_column :custom_fields, :name, :string, limit: 30
  end
end
