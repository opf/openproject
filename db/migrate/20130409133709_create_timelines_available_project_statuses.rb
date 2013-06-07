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

class CreateTimelinesAvailableProjectStatuses < ActiveRecord::Migration
  def self.up
    create_table(:timelines_available_project_statuses) do |t|
      t.belongs_to :project_type
      t.belongs_to :reported_project_status

      t.timestamps
    end

    add_index :timelines_available_project_statuses, :project_type_id
    add_index :timelines_available_project_statuses, :reported_project_status_id, :name => "index_avail_project_statuses_on_rep_project_status_id"
  end

  def self.down
    drop_table(:timelines_available_project_statuses)
  end
end
