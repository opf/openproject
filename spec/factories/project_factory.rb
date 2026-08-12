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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :project, parent: :workspace do
    transient do
      # example:
      #   member_with_permissions: {
      #     user => :view_work_packages
      #     other_user => [:view_work_packages, :edit_work_packages]
      #   }
      member_with_permissions { {} }

      # example:
      #   member_wih_roles: {
      #     user => role1,
      #     other_user => [role2, role3]
      #   }
      member_with_roles { {} }
    end

    workspace_type { "project" }

    sequence(:name) { |n| "My Project No. #{n}" }
    sequence(:identifier) { |n| Setting::WorkPackageIdentifier.semantic? ? "MPN#{n}" : "myproject_no_#{n}" }

    # Use this trait for specs that exercise semantic-mode behaviour.
    # Produces a deterministic uppercase identifier that satisfies
    # Projects::Identifier's semantic format constraints
    # (\A[A-Z][A-Z0-9_]*\z, max 10 chars).
    trait :semantic do
      sequence(:identifier) { |n| "PROJ#{n}".first(Projects::Identifier::SEMANTIC_IDENTIFIER_MAX_LENGTH) }
    end

    callback(:after_build) do |_project, evaluator|
      is_build_strategy = evaluator.instance_eval { @build_strategy.is_a? FactoryBot::Strategy::Build }
      uses_member_association = evaluator.member_with_permissions.present? || evaluator.member_with_roles.present?
      if is_build_strategy && uses_member_association
        raise ArgumentError,
              "Use create(...) with principals and member_with_permissions, member_with_roles traits."
      end
    end

    callback(:after_stub) do |_project, evaluator|
      uses_member_association = evaluator.member_with_permissions.present? || evaluator.member_with_roles.present?
      if uses_member_association
        raise ArgumentError,
              "To create memberships, you either need to use create(...) or use the `mock_permissions_for` " \
              "helper on the stubbed models"
      end
    end

    callback(:after_create) do |project, evaluator|
      evaluator.member_with_permissions.each do |principal, permission_or_permissions|
        role = create(:project_role, permissions: Array(permission_or_permissions))
        create(:member, principal:, project: project, roles: [role])
      end

      evaluator.member_with_roles.each do |principal, role_or_roles|
        create(:member, principal:, project: project, roles: Array(role_or_roles))
      end
    end

    factory :public_project do
      public { true } # Remark: public defaults to true
    end

    factory :private_project do
      public { false }
    end

    factory :template_project do
      sequence(:name) { |n| "Template project No. #{n}" }
      sequence(:identifier) { |n| "template_no_#{n}" }
      template
    end

    # Factories for
    # * portfolio
    # * program
    # are in separate files.

    factory :project_with_types do
      with_types

      factory :valid_project do
        callback(:after_build) do |project|
          project.types << build(:type_with_workflow)
        end
      end
    end
  end
end
