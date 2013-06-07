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

class CreateTimelinesColors < ActiveRecord::Migration
  def self.up
    create_table(:timelines_colors) do |t|
      t.column :name,    :string, :null => false
      t.column :hexcode, :string, :null => false, :length => 7

      t.column :position, :integer, :default => 1, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table(:timelines_colors)
  end
end
