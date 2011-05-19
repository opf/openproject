class RemoveCommentsFromWikiContent < ActiveRecord::Migration
  def self.up
    remove_column :wiki_contents, :comments
  end

  def self.down
    add_column :wiki_contents, :comments, :string
  end
end
