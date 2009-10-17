class AddMissingIndexesToWikiContents < ActiveRecord::Migration
  def self.up
    add_index :wiki_contents, :author_id
  end

  def self.down
    remove_index :wiki_contents, :author_id
  end
end
