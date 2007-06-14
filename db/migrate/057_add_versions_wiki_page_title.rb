class AddVersionsWikiPageTitle < ActiveRecord::Migration
  def self.up
    add_column :versions, :wiki_page_title, :string
  end

  def self.down
    remove_column :versions, :wiki_page_title
  end
end
