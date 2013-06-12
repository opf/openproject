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

class CreateTimelinesReportings < ActiveRecord::Migration
  def self.up
    create_table(:reportings) do |t|
      t.column :reported_project_status_comment, :text

      t.belongs_to :project
      t.belongs_to :reporting_to_project
      t.belongs_to :reported_project_status

      t.timestamps
    end
    add_index :reportings, :project_id
    add_index :reportings, :reporting_to_project_id
    add_index :reportings, :reported_project_status_id
  end

  def self.down
    drop_table(:reportings)
  end
end
