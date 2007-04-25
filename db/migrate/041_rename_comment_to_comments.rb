class RenameCommentToComments < ActiveRecord::Migration
  def self.up
    rename_column(:comments, :comment, :comments) if ActiveRecord::Base.connection.columns("comments").detect{|c| c.name == "comment"}
    rename_column(:wiki_contents, :comment, :comments) if ActiveRecord::Base.connection.columns("wiki_contents").detect{|c| c.name == "comment"}
    rename_column(:wiki_content_versions, :comment, :comments) if ActiveRecord::Base.connection.columns("wiki_content_versions").detect{|c| c.name == "comment"}
    rename_column(:time_entries, :comment, :comments) if ActiveRecord::Base.connection.columns("time_entries").detect{|c| c.name == "comment"}
    rename_column(:changesets, :comment, :comments) if ActiveRecord::Base.connection.columns("changesets").detect{|c| c.name == "comment"}
  end

  def self.down
    raise IrreversibleMigration
  end
end
