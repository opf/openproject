# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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

class Queries::Principals::Filters::MentionableOnWorkPackageFilter <
  Queries::Principals::Filters::PrincipalFilter
  def allowed_values
    # We don't care for the first value as we do not display the values visibly
    @allowed_values ||= ::WorkPackage.visible.pluck(:id).map { |id| [id, id.to_s] }
  end

  def type
    :list_optional
  end

  def key
    :mentionable_on_work_package
  end

  def scope
    case operator
    when '='
      principals_with_a_membership
    when '!'
      visible_scope.where.not(id: principals_with_a_membership.select(:id))
    end
  end

  def where
    '1=1'
  end

  private

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
