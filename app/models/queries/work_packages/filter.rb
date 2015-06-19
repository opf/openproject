#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

class Queries::WorkPackages::Filter < Queries::Filter
  self.filter_types_by_field = filter_types_by_field.merge(
     status_id:        :list_status,
     type_id:          :list,
     priority_id:      :list,
     subject:          :text,
     start_date:       :date,
     due_date:         :date,
     estimated_hours:  :integer,
     done_ratio:       :integer,
     project_id:       :list,
     category_id:      :list_optional,
     fixed_version_id: :list_optional,
     subproject_id:    :list_subprojects,
     assigned_to_id:   :list_optional,
     author_id:        :list,
     member_of_group:  :list_optional,
     assigned_to_role: :list_optional,
     responsible_id:   :list_optional,
     watcher_id:       :list
  )

  validates :field, inclusion: { in: Proc.new { filter_types_by_field.keys }, message: '%(value) is not a valid filter' }, unless: Proc.new { |filter| filter.field.to_s.starts_with?('cf_') }

  def self.add_filter_type_by_field(field, filter_type)
    filter_types_by_field[field.to_sym] = filter_type.to_sym
  end
end
