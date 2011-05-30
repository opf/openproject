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

class CreateWatchers < ActiveRecord::Migration
  def self.up
    create_table :watchers do |t|
      t.column :watchable_type, :string, :default => "", :null => false
      t.column :watchable_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :watchers
  end
end
