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
