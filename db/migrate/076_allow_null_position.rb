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

class AllowNullPosition < ActiveRecord::Migration
  def self.up
    # removes the 'not null' constraint on position fields
    change_column :issue_statuses, :position, :integer, :default => 1, :null => true
    change_column :roles, :position, :integer, :default => 1, :null => true
    change_column :trackers, :position, :integer, :default => 1, :null => true
    change_column :boards, :position, :integer, :default => 1, :null => true
    change_column :enumerations, :position, :integer, :default => 1, :null => true
  end

  def self.down
    # nothing to do
  end
end
