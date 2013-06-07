#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RenameCommentToComments < ActiveRecord::Migration
  def self.up
    rename_column(:comments, :comment, :comments) if ActiveRecord::Base.connection.columns(Comment.table_name).detect{|c| c.name == "comment"}
    rename_column(:wiki_contents, :comment, :comments) if ActiveRecord::Base.connection.columns(WikiContent.table_name).detect{|c| c.name == "comment"}
    rename_column(:wiki_content_versions, :comment, :comments) if ActiveRecord::Base.connection.columns("wiki_content_versions").detect{|c| c.name == "comment"}
    rename_column(:time_entries, :comment, :comments) if ActiveRecord::Base.connection.columns(TimeEntry.table_name).detect{|c| c.name == "comment"}
    rename_column(:changesets, :comment, :comments) if ActiveRecord::Base.connection.columns(Changeset.table_name).detect{|c| c.name == "comment"}
  end

  def self.down
    raise IrreversibleMigration
  end
end
