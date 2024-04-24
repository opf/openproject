# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

module WorkPackageMembers
  class BaseContract < ::ModelContract
    delegate :project,
             to: :model

    attribute :roles

    validate :user_allowed_to_manage
    validate :role_grantable
    validate :single_non_inherited_role
    validate :project_set
    validate :entity_set

    attribute_alias(:user_id, :principal)

    private

    def user_allowed_to_manage
      return if user_allowed_to_manage? && (!model.principal || model.principal != user)

      errors.add :base, :error_unauthorized
    end

    def user_allowed_to_manage?
      user.allowed_in_project?(:share_work_packages, model.project)
    end

    def single_non_inherited_role
      errors.add(:roles, :more_than_one) if active_non_inherited_roles.count > 1
    end

    def role_grantable
      errors.add(:roles, :ungrantable) unless active_roles.all? { _1.is_a?(WorkPackageRole) }
    end

    def project_set
      errors.add(:project, :blank) if project.nil?
    end

    def active_roles
      active_member_roles.map(&:role)
    end

    def active_non_inherited_roles
      active_member_roles.reject(&:inherited_from).map(&:role)
    end

    def active_member_roles
      model.member_roles.reject(&:marked_for_destruction?)
    end

    def entity_set
      errors.add(:entity, :blank) if entity_id.nil?
    end
  end
end
