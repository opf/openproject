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

class CreateChangesets < ActiveRecord::Migration
  def self.up
    create_table :changesets do |t|
      t.column :repository_id, :integer, :null => false
      t.column :revision, :integer, :null => false
      t.column :committer, :string, :limit => 30
      t.column :committed_on, :datetime, :null => false
      t.column :comments, :text
    end
    add_index :changesets, [:repository_id, :revision], :unique => true, :name => :changesets_repos_rev
  end

  def self.down
    drop_table :changesets
  end
end
