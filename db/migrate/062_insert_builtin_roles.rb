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

class InsertBuiltinRoles < ActiveRecord::Migration
  def self.up
    Role.connection.schema_cache.clear!
    Role.reset_column_information
    nonmember = Role.new(:name => 'Non member', :position => 0)
    nonmember.builtin = Role::BUILTIN_NON_MEMBER
    nonmember.save

    anonymous = Role.new(:name => 'Anonymous', :position => 0)
    anonymous.builtin = Role::BUILTIN_ANONYMOUS
    anonymous.save
  end

  def self.down
    Role.destroy_all 'builtin <> 0'
  end
end
