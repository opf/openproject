# frozen_string_literal: true

#-- copyright
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::Principals::Filters::MentionableOnWorkPackageFilter <
  Queries::Principals::Filters::PrincipalFilter
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
    :mentionable_on_work_package
  end

  def human_name
    "mentionable" # Only for Internal use, not visible in the UI
  end

  def apply_to(query_scope)
    case operator
    when "="
      query_scope.where(id: principals_with_a_membership)
    when "!"
      query_scope.where(id: visible_scope.where.not(id: principals_with_a_membership.select(:id)))
    end
  end

  private

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
  end

  def principals_with_a_membership
    visible_scope.where(id: work_package_members.select(:user_id))
                 .or(visible_scope.where(id: project_members.select(:user_id)))
  end

  def visible_scope
    Principal.visible(User.current)
             .includes(members: :roles)
             .references(members: :roles)
  end

  def work_package_members
    Member.joins(:member_roles)
          .of_work_package(values)
          .where(member_roles: { role_id: mentionable_work_package_role_ids })
  end

  def mentionable_work_package_role_ids
    Role.where(builtin: [Role::BUILTIN_WORK_PACKAGE_EDITOR,
                         Role::BUILTIN_WORK_PACKAGE_COMMENTER])
        .select(:id)
  end

  def project_members
    Member.of_project(projects)
          .where(entity: nil)
  end

  def work_packages
    WorkPackage.where(id: values)
  end

  def projects
    Project.where(id: work_packages.select(:project_id))
  end
end
