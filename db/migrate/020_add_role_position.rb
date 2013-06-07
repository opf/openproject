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

class AddRolePosition < ActiveRecord::Migration
  def self.up
    add_column :roles, :position, :integer, :default => 1
    Role.find(:all).each_with_index {|role, i| role.update_attribute(:position, i+1)}
  end

  def self.down
    remove_column :roles, :position
  end
end
