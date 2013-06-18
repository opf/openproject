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
