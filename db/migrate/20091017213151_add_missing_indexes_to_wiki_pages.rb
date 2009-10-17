class AddMissingIndexesToWikiPages < ActiveRecord::Migration
  def self.up
    add_index :wiki_pages, :wiki_id
    add_index :wiki_pages, :parent_id
  end

  def self.down
    remove_index :wiki_pages, :wiki_id
    remove_index :wiki_pages, :parent_id
  end
end
