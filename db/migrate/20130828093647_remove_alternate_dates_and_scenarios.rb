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

class RemoveAlternateDatesAndScenarios < ActiveRecord::Migration
  def up
    drop_table(:alternate_dates)
    drop_table(:scenarios)
  end

  def down
    create_table(:scenarios) do |t|
      t.column :name,        :string, :null => false
      t.column :description, :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :scenarios, :project_id

    create_table(:alternate_dates) do |t|
      t.column :start_date, :date, :null => false
      t.column :due_date,   :date, :null => false

      t.belongs_to :scenario
      t.belongs_to :planning_element

      t.timestamps
    end

    add_index :alternate_dates, :planning_element_id
    add_index :alternate_dates, :scenario_id

    add_index :alternate_dates,
              [:updated_at, :planning_element_id, :scenario_id],
              :unique => true,
              :name => 'index_ad_on_updated_at_and_planning_element_id'
  end
end
