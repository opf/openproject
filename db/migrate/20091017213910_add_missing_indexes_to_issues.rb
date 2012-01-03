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
