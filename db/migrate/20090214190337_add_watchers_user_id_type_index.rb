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

class AddWatchersUserIdTypeIndex < ActiveRecord::Migration
  def self.up
    add_index :watchers, [:user_id, :watchable_type], :name => :watchers_user_id_type
  end

  def self.down
    remove_index :watchers, :name => :watchers_user_id_type
  end
end
