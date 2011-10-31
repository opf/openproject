#-- encoding: UTF-8
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

class AddMissingIndexesToMembers < ActiveRecord::Migration
  def self.up
    add_index :members, :user_id
    add_index :members, :project_id
  end

  def self.down
    remove_index :members, :user_id
    remove_index :members, :project_id
  end
end
