class RenameIssueCategoryToCategory < ActiveRecord::Migration
  def change
    rename_table :issue_categories, :categories
  end
end
