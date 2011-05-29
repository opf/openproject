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

class AddMissingIndexesToWorkflows < ActiveRecord::Migration
  def self.up
    add_index :workflows, :old_status_id
    add_index :workflows, :role_id
    add_index :workflows, :new_status_id
  end

  def self.down
    remove_index :workflows, :old_status_id
    remove_index :workflows, :role_id
    remove_index :workflows, :new_status_id
  end
end
