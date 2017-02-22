class RemoveCategoryNameRestriction < ActiveRecord::Migration[5.0]
  def change
    change_column :categories, :name, :string, limit: 256
  end
end
