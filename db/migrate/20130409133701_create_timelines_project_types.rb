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

class CreateTimelinesProjectTypes < ActiveRecord::Migration
  def self.up
    create_table(:timelines_project_types) do |t|
      t.column :name,               :string,  :default => '',   :null => false
      t.column :allows_association, :boolean, :default => true, :null => false
      t.column :position,           :integer, :default => 1,    :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :timelines_project_types
  end
end
