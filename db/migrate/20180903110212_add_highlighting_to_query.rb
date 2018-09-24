class AddHighlightingToQuery < ActiveRecord::Migration[5.1]
  def change
    add_column :queries, :highlighting_mode, :text
  end
end
