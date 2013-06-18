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

class AddDeletedAtToTimelinesPlanningElements < ActiveRecord::Migration
  def self.up
    add_column :timelines_planning_elements, :deleted_at, :datetime
  end

  def self.down
    remove_column :timelines_planning_elements, :deleted_at
  end
end
