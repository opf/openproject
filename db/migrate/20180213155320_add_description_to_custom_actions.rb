class AddDescriptionToCustomActions < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_actions, :description, :text
  end
end
