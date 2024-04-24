#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#++

module Members
  class BaseContract < ::ModelContract
    delegate :principal,
             :project,
             :new_record?,
             to: :model

    attribute :roles

    validate :user_allowed_to_manage
    validate :roles_grantable
    validate :project_set
    validate :project_manageable

    def assignable_projects
      Project
        .active
        .where(id: Project.allowed_to(user, :manage_members))
    end

    private

    def user_allowed_to_manage
      errors.add :base, :error_unauthorized unless user_allowed_to_manage?
    end

    def roles_grantable
      unmarked_roles = model.member_roles.reject(&:marked_for_destruction?).map(&:role)

      errors.add(:roles, :ungrantable) unless unmarked_roles.all? { |r| role_grantable?(r) }
    end

    def project_set
      errors.add(:project, :blank) unless project_set_or_admin?
    end

    def project_manageable
      errors.add(:project, :invalid) unless project_manageable_or_blank?
    end

    def role_grantable?(role)
      role.builtin == Role::NON_BUILTIN &&
        ((model.project && role.instance_of?(ProjectRole)) || (!model.project && role.instance_of?(GlobalRole)))
    end

    def user_allowed_to_manage? # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      # rubocop:disable Performance/RedundantEqualityComparisonBlock
      if model.project.present? && model.roles.empty?
        user.allowed_in_any_project?(:manage_members)
      elsif model.project.present? && model.roles.all? { |r| r.is_a?(ProjectRole) }
        user.allowed_in_project?(:manage_members, model.project)
      elsif model.project.nil? && model.roles.any? { |r| r.is_a?(GlobalRole) }
        user.admin?
      else
        # This state is invalid to be saved so other validations will prevent this from being valid
        # but we cannot tell whether the user is allowed to manage members for this.
        true
      end
      # rubocop:enable Performance/RedundantEqualityComparisonBlock
    end

    def project_manageable_or_blank?
      !model.project || user.allowed_in_project?(:manage_members, model.project)
    end

    def project_set_or_admin?
      model.project || user.admin?
    end
  end
end
