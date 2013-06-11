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

class AddTimelinesResponsibleIdToProjects < ActiveRecord::Migration
  def self.up
    change_table(:projects) do |t|
      t.belongs_to :timelines_responsible

      t.index :timelines_responsible_id
    end
  end

  def self.down
    change_table(:projects) do |t|
      t.remove_belongs_to :timelines_responsible
    end
  end
end
