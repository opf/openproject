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

class MakeGroupsUsersAModel < ActiveRecord::Migration
  def self.up
    remove_index :groups_users, :name => :groups_users_ids
    rename_table :groups_users, :group_users
    add_index :group_users, [:group_id, :user_id], :name => :group_user_ids, :unique => true
  end

  def self.down
    remove_index :group_users, :name => :group_user_ids
    rename_table :group_users, :groups_users
    add_index :groups_users, [:group_id, :user_id], :name => :groups_users_ids, :unique => true
  end
end
