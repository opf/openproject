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

class AddIssuesNestedSetsColumns < ActiveRecord::Migration

  class Issue < ActiveRecord::Base; end

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
