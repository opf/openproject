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

class AddIssuesNestedSetsColumns < ActiveRecord::Migration
  def self.up
    add_column :issues, :parent_id, :integer, :default => nil
    add_column :issues, :root_id, :integer, :default => nil
    add_column :issues, :lft, :integer, :default => nil
    add_column :issues, :rgt, :integer, :default => nil

    Issue.update_all("parent_id = NULL, root_id = id, lft = 1, rgt = 2")
  end

  def self.down
    remove_column :issues, :parent_id
    remove_column :issues, :root_id
    remove_column :issues, :lft
    remove_column :issues, :rgt
  end
end
