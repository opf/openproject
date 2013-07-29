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

class EnabledPlanningElementType < ActiveRecord::Base
  unloadable

  self.table_name = 'enabled_planning_element_types'

  belongs_to :project,               :class_name  => 'Project',
                                     :foreign_key => 'project_id'
  belongs_to :type, :foreign_key => 'planning_element_type_id'

  attr_accessible :planning_element_type_id

  validates_presence_of :type, :project
end

