class AddAllowNonOpenVersionsToCustomFields < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_fields, :allow_non_open_versions, :boolean, default: false
  end
end
