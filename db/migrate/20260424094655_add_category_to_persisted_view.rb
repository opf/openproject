# frozen_string_literal: true

class AddCategoryToPersistedView < ActiveRecord::Migration[8.1]
  def change
    add_column :persisted_views, :category, :string, null: true
    add_index :persisted_views, :category
  end
end
