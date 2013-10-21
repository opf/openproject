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
object @type
attributes :id, :name, :in_aggregation, :is_milestone, :position, :is_default

node :color, if: lambda{|type| type.color.present?} do |type|
  {id: type.color.id, name: type.color.name, hexcode: type.color.hexcode}
end

node :created_at, if: lambda{|project| project.created_at.present?} {|project| project.created_at.utc.iso8601}
node :updated_at, if: lambda{|project| project.updated_at.present?} {|project| project.updated_at.utc.iso8601}

#api.planning_element_type do
#  api.id(planning_element_type.id)
#  api.name(planning_element_type.name)
#
#  api.in_aggregation(planning_element_type.in_aggregation)
#  api.is_milestone(planning_element_type.is_milestone)
#  api.is_default(planning_element_type.is_default)
#
#  api.position(planning_element_type.position)
#
#  color = planning_element_type.color
#  if color.present?
#    api.color(:id => color.id, :name => color.name, :hexcode => color.hexcode)
#  end
#
#  api.created_at(planning_element_type.created_at.utc) if planning_element_type.created_at
#  api.updated_at(planning_element_type.updated_at.utc) if planning_element_type.updated_at
#end
