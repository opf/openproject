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

class UpdateProjectsTypesService < BaseProjectService
  def call(type_ids)
    type_ids = standard_types if type_ids.nil? || type_ids.empty?

    if types_missing?(type_ids)
      project.errors.add(:types,
                         :in_use_by_work_packages,
                         types: missing_types(type_ids).map(&:name).join(', '))
      false
    else
      project.type_ids = type_ids

      true
    end
  end

  protected

  def standard_types
    type = ::Type.standard_type
    if type.nil?
      []
    else
      [type.id]
    end
  end

  def types_missing?(type_ids)
    !missing_types(type_ids).empty?
  end

  def missing_types(type_ids)
    types_used_by_work_packages.select { |t| !type_ids.include?(t.id) }
  end

  def types_used_by_work_packages
    @types_used_by_work_packages ||= project.types_used_by_work_packages
  end
end
