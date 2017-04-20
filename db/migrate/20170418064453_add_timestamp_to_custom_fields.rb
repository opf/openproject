class AddTimestampToCustomFields < ActiveRecord::Migration[5.0]
  def up
    add_column :custom_fields, :created_at, :datetime unless column_exists? :custom_fields, :created_at
    add_column :custom_fields, :updated_at, :datetime unless column_exists? :custom_fields, :updated_at

    add_column :custom_options, :created_at, :datetime unless column_exists? :custom_options, :created_at
    add_column :custom_options, :updated_at, :datetime unless column_exists? :custom_options, :updated_at
  end

  def down
    remove_column :custom_fields, :created_at, :datetime
    remove_column :custom_fields, :updated_at, :datetime

    remove_column :custom_options, :created_at, :datetime
    remove_column :custom_options, :updated_at, :datetime
  end
end
