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

class AddMissingIndexesToIssues < ActiveRecord::Migration
  def self.up
    add_index :issues, :status_id
    add_index :issues, :category_id
    add_index :issues, :assigned_to_id
    add_index :issues, :fixed_version_id
    add_index :issues, :tracker_id
    add_index :issues, :priority_id
    add_index :issues, :author_id
  end

  def self.down
    remove_index :issues, :status_id
    remove_index :issues, :category_id
    remove_index :issues, :assigned_to_id
    remove_index :issues, :fixed_version_id
    remove_index :issues, :tracker_id
    remove_index :issues, :priority_id
    remove_index :issues, :author_id
  end
end
