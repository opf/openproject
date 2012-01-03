#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
