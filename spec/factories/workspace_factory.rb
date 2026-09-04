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

FactoryBot.define do
  factory :workspace, class: "Project" do
    transient do
      no_types { false }
      disable_modules { [] }
      members { [] }

      types { [] }
    end

    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    enabled_module_names { OpenProject::AccessControl.available_project_modules }
    public { false }
    templated { false }

    callback(:after_build) do |project, evaluator|
      disabled_modules = Array(evaluator.disable_modules).map(&:to_s)
      project.enabled_module_names = project.enabled_module_names - disabled_modules

      # Most specs never name a type but still expect their project to hold work packages, so a
      # project gets the Default type unless the caller opts out. `build(:type_default)` finds the
      # existing one where there already is one, so projects in the same example share it.
      enabled_types = evaluator.types
      enabled_types = [build(:type_default)] if enabled_types.empty? && !evaluator.no_types

      # Callers name either a type or one of its variants. A type contributes its base
      # variant, which is the configuration it uses where none was chosen.
      #
      # An unsaved type has no base variant yet — it creates one on save — and the join row
      # cannot be inserted without one, so it is persisted first.
      enabled_types.each { |requested| requested.save! if requested.new_record? }

      project.project_types = enabled_types.map do |requested|
        ProjectType.new(type: type_of(requested), variant: variant_of(requested))
      end
    end

    callback(:after_stub) do |project, evaluator|
      # No rows exist to read back from, and assigning the association on a record that already
      # looks persisted would insert them for real.
      project.association(:project_types).target = evaluator.types.map do |requested|
        ProjectType.new(type: type_of(requested)).tap do |project_type|
          project_type.variant = requested if requested.is_a?(TypeVariant)
        end
      end
      project.association(:project_types).loaded!
    end

    callback(:after_create) do |project, evaluator|
      evaluator.members.each do |user, roles|
        Members::CreateService
          .new(user: User.system, contract_class: EmptyContract)
          .call(principal: user, project:, roles: Array(roles))
      end
    end

    trait :with_status do
      status_code { Project.status_codes.keys.sample }
      status_explanation { "some explanation" }
    end

    trait :with_types do
      types do
        if instance_variable_get(:@build_strategy).is_a?(FactoryBot::Strategy::Stub)
          [build_stubbed(:type)]
        else
          [build(:type)]
        end
      end
    end

    trait :archived do
      active { false }
    end

    trait :updated_a_long_time_ago do
      created_at { 2.years.ago }
      updated_at { 2.years.ago }
    end

    trait :template do
      templated { true }
    end

    trait :with_internal_wiki do
      transient do
        start_page { "Wiki" }
      end

      callback(:after_create) do |workspace, evaluator|
        create(:internal_wiki_provider) if Wikis::InternalProvider.none?

        workspace.create_wiki(start_page: evaluator.start_page)
      end
    end
  end
end

# A workspace factory accepts a type or one of its variants wherever types are named.
def type_of(requested)
  requested.is_a?(TypeVariant) ? requested.type : requested
end

def variant_of(requested)
  return requested if requested.is_a?(TypeVariant)

  requested.default_variant || requested.variants.detect(&:is_default_variant?)
end

def enabled_types_of(project)
  project.project_types.filter_map(&:type).sort_by { |type| type.position || 0 }
end
