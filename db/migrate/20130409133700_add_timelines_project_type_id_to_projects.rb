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

class AddTimelinesProjectTypeIdToProjects < ActiveRecord::Migration
  def self.up
    change_table(:projects) do |t|
      t.belongs_to :timelines_project_type

      t.index :timelines_project_type_id
    end
  end

  def self.down
    change_table(:projects) do |t|
      t.remove_belongs_to :timelines_project_type
    end
  end
end
