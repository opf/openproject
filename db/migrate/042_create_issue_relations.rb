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

class CreateIssueRelations < ActiveRecord::Migration
  def self.up
    create_table :issue_relations do |t|
      t.column :issue_from_id, :integer, :null => false
      t.column :issue_to_id, :integer, :null => false
      t.column :relation_type, :string, :default => "", :null => false
      t.column :delay, :integer
    end
  end

  def self.down
    drop_table :issue_relations
  end
end
