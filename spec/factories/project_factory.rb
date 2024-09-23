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
  factory :project do
    transient do
      no_types { false }
      disable_modules { [] }
      members { [] }
    end

    sequence(:name) { |n| "My Project No. #{n}" }
    sequence(:identifier) { |n| "myproject_no_#{n}" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    enabled_module_names { OpenProject::AccessControl.available_project_modules }
    public { false }
    templated { false }

    callback(:after_build) do |project, evaluator|
      disabled_modules = Array(evaluator.disable_modules).map(&:to_s)
      project.enabled_module_names = project.enabled_module_names - disabled_modules

      if !evaluator.no_types && project.types.empty?
        project.types << (Type.where(is_standard: true).first || build(:type_standard))
      end
    end

    callback(:after_create) do |project, evaluator|
      evaluator.members.each do |user, roles|
        Members::CreateService
          .new(user: User.system, contract_class: EmptyContract)
          .call(principal: user, project:, roles: Array(roles))
      end
    end

    factory :public_project do
      public { true } # Remark: public defaults to true
    end

    factory :template_project do
      sequence(:name) { |n| "Template project No. #{n}" }
      sequence(:identifier) { |n| "template_no_#{n}" }
      templated { true }
    end

    factory :project_with_types do
      # using initialize_with types to prevent
      # the project's initialize function looking for the default type
      # when we will be setting the type later on anyway
      initialize_with do
        types = if instance_variable_get(:@build_strategy).is_a?(FactoryBot::Strategy::Stub)
                  [build_stubbed(:type)]
                else
                  [build(:type)]
                end

        new(types:)
      end

      factory :valid_project do
        callback(:after_build) do |project|
          project.types << build(:type_with_workflow)
        end
      end
    end

    trait :with_status do
      status_code { Project.status_codes.keys.sample }
      status_explanation { "some explanation" }
    end

    trait :archived do
      active { false }
    end

    trait :updated_a_long_time_ago do
      created_at { 2.years.ago }
      updated_at { 2.years.ago }
    end
  end
end
