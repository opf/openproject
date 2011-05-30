#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CreateChangesetsIssues < ActiveRecord::Migration
  def self.up
    create_table :changesets_issues, :id => false do |t|
      t.column :changeset_id, :integer, :null => false
      t.column :issue_id, :integer, :null => false
    end
    add_index :changesets_issues, [:changeset_id, :issue_id], :unique => true, :name => :changesets_issues_ids
  end

  def self.down
    drop_table :changesets_issues
  end
end
