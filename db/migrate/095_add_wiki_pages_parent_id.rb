class AddWikiPagesParentId < ActiveRecord::Migration
  def self.up
    add_column :wiki_pages, :parent_id, :integer, :default => nil
  end

  def self.down
    remove_column :wiki_pages, :parent_id
  end
end
