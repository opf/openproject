#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Reporting < ActiveRecord::Base
  self.table_name = 'reportings'

  belongs_to :project
  belongs_to :reporting_to_project,    class_name:  'Project',
                                       foreign_key: 'reporting_to_project_id'

  belongs_to :reported_project_status, class_name:  'ReportedProjectStatus',
                                       foreign_key: 'reported_project_status_id'

  validates_presence_of :project, :reporting_to_project

  validates_uniqueness_of :reporting_to_project_id, scope: :project_id

  def visible?(user = User.current)
    reporting_to_project.visible?(user) && project.visible?(user)
  end

  def possible_reported_project_statuses
    reporting_to_project.project_type.present? ?
      reporting_to_project.project_type.reported_project_statuses :
      []
  end
end
