class AddMissingIndexesOnWikiMenuItems < ActiveRecord::Migration
  def self.up
    add_index :wiki_menu_items, [:wiki_id, :title]
    add_index :wiki_menu_items, :parent_id
  end

  def self.down
    remove_index :wiki_menu_items, [:wiki_id, :title]
    remove_index :wiki_menu_items, :parent_id
  end
end
