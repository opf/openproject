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

class CreateTimelinesProjectAssociations < ActiveRecord::Migration
  def self.up
    create_table(:timelines_project_associations) do |t|
      t.belongs_to :project_a
      t.belongs_to :project_b

      t.column :description, :text

      t.timestamps
    end

    add_index :timelines_project_associations, :project_a_id
    add_index :timelines_project_associations, :project_b_id
  end

  def self.down
    drop_table :timelines_project_associations
  end
end
