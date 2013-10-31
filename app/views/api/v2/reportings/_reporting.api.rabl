#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
object @reporting
attributes :id

node :reported_project_status, if: ->(reporting){reporting.reported_project_status} do |reporting|
 {id: reporting.reported_project_status.id,
  name: reporting.reported_project_status.name}
end

node :reported_project_status_comment, id: ->(reporting){reporting.reported_project_status_comment.present?} do |reporting|
  reporting.reported_project_status_comment
end

node :created_at, if: lambda{|project| project.created_at.present?} {|project| project.created_at.utc.iso8601}
node :updated_at, if: lambda{|project| project.updated_at.present?} {|project| project.updated_at.utc.iso8601}

child :project do
  attributes :id, :identifier, :name
end

node :reporting_to_project do |reporting|
  {id: reporting.reporting_to_project.id,
   identifier: reporting.reporting_to_project.identifier,
   name: reporting.reporting_to_project.name}
end