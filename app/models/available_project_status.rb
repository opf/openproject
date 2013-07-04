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

class AvailableProjectStatus < ActiveRecord::Base
  unloadable

  self.table_name = 'available_project_statuses'

  belongs_to :project_type,            :class_name  => 'ProjectType',
                                       :foreign_key => 'project_type_id'
  belongs_to :reported_project_status, :class_name  => 'ReportedProjectStatus',
                                       :foreign_key => 'reported_project_status_id'

  attr_accessible :reported_project_status_id

  validates_presence_of :reported_project_status, :project_type
end
