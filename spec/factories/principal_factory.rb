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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :principal do
    transient do
      # example:
      #   member_with_permissions: {
      #     project => [:view_work_packages]
      #     work_package => [:view_work_packages, :edit_work_packages]
      #   }
      member_with_permissions { {} }

      # example:
      #   member_wih_roles: {
      #     project => [role1],
      #     work_package => [role2, role3]
      #   }
      member_with_roles { {} }

      global_roles { [] }
      global_permissions { [] }
    end

    callback(:after_build) do |_principal, evaluator|
      is_build_strategy = evaluator.instance_eval { @build_strategy.is_a? FactoryBot::Strategy::Build }
      uses_member_association = evaluator.member_with_permissions.present? ||
        evaluator.member_with_roles.present? ||
        evaluator.global_roles.present? ||
        evaluator.global_permissions.present?
      if is_build_strategy && uses_member_association
        raise ArgumentError,
              "Use create(...) with principals and member_with_permissions, member_with_roles, global_roles, global_permissions traits."
      end
    end

    callback(:after_stub) do |_principal, evaluator|
      uses_member_association = evaluator.member_with_permissions.present? ||
        evaluator.member_with_roles.present? ||
        evaluator.global_roles.present? ||
        evaluator.global_permissions.present?
      if uses_member_association
        raise ArgumentError,
              "To create memberships, you either need to use create(...) or use the `mock_permissions_for` helper on the stubbed models"
      end
    end

    callback(:after_create) do |principal, evaluator|
      evaluator.member_with_permissions.each do |object, permissions|
        if object.is_a?(Project)
          role = create(:project_role, permissions:)
          create(:member, principal:, project: object, roles: [role])
        elsif Member.can_be_member_of?(object)
          project = object.respond_to?(:project) ? object.project : nil
          role_factory = :"#{object.model_name.element}_role"

          role = create(role_factory, permissions:)
          create(:member, principal:, entity: object, project:, roles: [role])
        end
      end

      evaluator.member_with_roles.each do |object, role_or_roles|
        case object
        when Project
          create(:member, principal:, project: object, roles: Array(role_or_roles))
        when WorkPackage
          create(:member, principal:, entity: object, project: object.project, roles: Array(role_or_roles))
        when ProjectQuery
          create(:member, principal:, entity: object, project: nil, roles: Array(role_or_roles))
        end
      end

      if evaluator.global_permissions.present?
        global_role = create(:global_role, permissions: Array(evaluator.global_permissions))
        create(:global_member, principal:, roles: [global_role])
      end

      if evaluator.global_roles.present?
        create(:global_member, principal:, roles: evaluator.global_roles)
      end
    end
  end
end
