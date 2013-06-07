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

class AddMemberRolesInheritedFrom < ActiveRecord::Migration
  def self.up
    add_column :member_roles, :inherited_from, :integer
  end

  def self.down
    remove_column :member_roles, :inherited_from
  end
end
