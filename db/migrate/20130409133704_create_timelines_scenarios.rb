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

class CreateTimelinesScenarios < ActiveRecord::Migration
  def self.up
    create_table(:timelines_scenarios) do |t|
      t.column :name,        :string, :null => false
      t.column :description, :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :timelines_scenarios, :project_id
  end

  def self.down
    drop_table(:timelines_scenarios)
  end
end
