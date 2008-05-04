class AddWikiPagesProtected < ActiveRecord::Migration
  def self.up
    add_column :wiki_pages, :protected, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :wiki_pages, :protected
  end
end
