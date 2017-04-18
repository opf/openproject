class AddTimestampToCustomFields < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_fields, :created_at, :datetime
    add_column :custom_fields, :updated_at, :datetime

    add_column :custom_options, :updated_at, :datetime
    add_column :custom_options, :created_at, :datetime
  end
end
