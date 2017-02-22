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

collection @planning_elements => :planning_elements
attributes :id,
           :subject,
           :description,
           :done_ratio,
           :estimated_hours,
           :project_id,
           :type_id,
           :category_id,
           :priority_id,
           :fixed_version_id,
           :status_id,
           :parent_id,
           :child_ids,
           :responsible_id,
           :author_id,
           :assigned_to_id

node :start_date, :if => lambda{|pe| pe.start_date.present?} { |pe| pe.start_date.to_formatted_s(:db) }
node :due_date, :if => lambda{|pe| pe.due_date.present?} {|pe| pe.due_date.to_formatted_s(:db) }

node :created_at, if: lambda{|pe| pe.created_at.present?} {|pe| pe.created_at.utc}
node :updated_at, if: lambda{|pe| pe.updated_at.present?} {|pe| pe.updated_at.utc}

node do |element|
  Hash[element.custom_values.map { |cv| ["cf_#{cv.custom_field_id}", cv.value] }]
end
