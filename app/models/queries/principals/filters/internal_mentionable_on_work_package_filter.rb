# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

class Queries::Principals::Filters::InternalMentionableOnWorkPackageFilter <
    Queries::Principals::Filters::PrincipalFilter
  validate :values_are_a_single_work_package_id

  def allowed_values
    raise NotImplementedError, "There would be too many candidates"
  end

  def allowed_values_subset
    @allowed_values_subset ||= ::WorkPackage.visible
  end

  def type
    :list_optional
  end

  def key
    :internal_mentionable_on_work_package
  end

  def human_name
    "internal mentionable" # Only for Internal use, not visible in the UI
  end

  def apply_to(query_scope)
    case operator
    when "="
      query_scope.where(id: project_members.select(:user_id))
    when "!"
      query_scope.where.not(id: project_members.select(:user_id))
    end
  end

  def permission
    :view_internal_comments
  end

  private

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
  end

  def values_are_a_single_work_package_id
    errors.add(:values, :single_value_requirement) if values.size > 1
  end

  def project_members
    Member.of_project(work_package.project)
          .joins(roles: :role_permissions)
          .where(role_permissions: { permission: })
  end

  def work_package
    WorkPackage.visible.find(values.first)
  end
end
