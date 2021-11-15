class AddContentOrientationToCustomFields < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_fields, :content_right_to_left, :boolean, default: false
  end
end
