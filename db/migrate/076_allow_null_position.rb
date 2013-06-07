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
