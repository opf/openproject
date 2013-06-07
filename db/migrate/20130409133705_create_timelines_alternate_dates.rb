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

class CreateTimelinesAlternateDates < ActiveRecord::Migration
  def self.up
    create_table(:timelines_alternate_dates) do |t|
      t.column :start_date, :date, :null => false
      t.column :end_date,   :date, :null => false

      t.belongs_to :scenario
      t.belongs_to :planning_element

      t.timestamps

    end
    add_index :timelines_alternate_dates, :planning_element_id
    add_index :timelines_alternate_dates, :scenario_id
  end

  def self.down
    drop_table(:timelines_alternate_dates)
  end
end
