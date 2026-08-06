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

      # Transient on purpose. Assigning the `types` association writes the member handed in
      # straight into the in-memory collection, so a variant stays there while the association
      # itself reads the roots the project_types rows name — the two then disagree. Building the
      # rows and naming (root, variant) explicitly keeps the association the single answer.
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

      enabled_types = evaluator.types
      if enabled_types.empty? && !evaluator.no_types
        enabled_types = [Type.where(is_standard: true).first || build(:type_standard)]
      end

      # Assigned through the association rather than by building project_types directly, so that
      # #types answers before the project is saved — the work package factory reads it during its
      # own build. Only the roots go in; the variant is then named on the join records the
      # assignment built, which are the same objects the save inserts.
      project.types = enabled_types.map(&:root)
      project.project_types.zip(enabled_types).each do |project_type, requested|
        project_type.variant = requested if requested.variant?
      end
    end

    callback(:after_stub) do |project, evaluator|
      # No rows exist to read back from, and assigning the association on a record that already
      # looks persisted would insert them for real.
      project.association(:types).target = evaluator.types.map(&:root)
      project.association(:types).loaded!
    end

    callback(:after_create) do |project, evaluator|
      # Drop what the build primed so both associations answer from the rows just written —
      # roots for #types, and the (root, variant) pair for #project_types.
      project.project_types.reset
      project.association(:types).reset

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
