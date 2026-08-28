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
  factory :type do
    # No position: it is acts_as_list's to assign, which appends on create. Sequencing it here
    # made the value depend on how many types the whole rspec process had built before this one,
    # so an unrelated spec creating a type could shift this one ahead of :type_task and silently
    # become project.enabled_types.first / the work_package factory's type fallback.
    sequence(:name) { |n| "Type No. #{n}" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }

    # Configuration lives on the variant, not the type. These are kept as aliases so the many
    # call sites that configure a type keep reading naturally: they write its base variant.
    transient do
      custom_fields { [] }
      patterns { nil }
      default_work_package_description { nil }
      attribute_groups { nil }
      default_variant_enabled_in_all_projects { false }
    end

    callback(:after_create) do |type, evaluator|
      configuration = {}
      configuration[:patterns] = evaluator.patterns unless evaluator.patterns.nil?
      unless evaluator.default_work_package_description.nil?
        configuration[:default_work_package_description] = evaluator.default_work_package_description
      end
      configuration[:attribute_groups] = evaluator.attribute_groups unless evaluator.attribute_groups.nil?
      configuration[:enabled_in_new_projects] = evaluator.default_variant_enabled_in_all_projects

      type.default_variant.update!(configuration) if configuration.any?
      type.default_variant.custom_fields = evaluator.custom_fields if evaluator.custom_fields.any?
    end

    factory :type_with_workflow, class: "Type" do
      callback(:after_create) do |t|
        variant = t.default_variant || t.variants.find_by!(is_default_variant: true)
        create(:workflow_with_default_status, type_variant: variant)
      end
    end

    factory :type_with_relation_query_group, class: "Type" do
      transient do
        relation_filter { "parent" }
      end

      callback(:after_create) do |t, evaluator|
        query = create(:query)
        query.add_filter(evaluator.relation_filter.to_s, "=", [Queries::Filters::TemplatedValue::KEY])
        query.save
        variant = t.default_variant
        variant.attribute_groups = variant.default_attribute_groups +
                                   [["Embedded table for #{evaluator.relation_filter}", [:"query_#{query.id}"]]]
        variant.save!
      end
    end
  end

  # Patterns live on the configuration, so the trait writes the type's base variant.
  trait :with_subject_pattern do
    callback(:after_create) do |t|
      t.default_variant.update!(
        patterns: { subject: { blueprint: "{{author}} - {{status}}/{{type}} - {{id}}", enabled: true } }
      )
    end
  end

  # The type the workspace factory gives a project whose spec names none. "Default" is reserved
  # for it: specs name their own types "Task", "Bug", … and a shared name would collide with the
  # type they create themselves.
  factory :type_default, parent: :type do
    name { "Default" }

    initialize_with { Type.find_or_initialize_by(name:) }
  end

  # Named seed types: find-or-create by name so specs that share "Bug" / "Task" do not collide.
  # Nested under :type so configuration transients (custom_fields, patterns, …) still apply to the
  # base variant after create.
  factory :type_bug, parent: :type do
    name { "Bug" }
    position { 1 }

    initialize_with { Type.find_or_initialize_by(name:) }

    factory :type_feature do
      name { "Feature" }
      position { 2 }
      default_variant_enabled_in_all_projects { true }
    end

    factory :type_support do
      name { "Support" }
      position { 3 }
    end

    factory :type_task do
      name { "Task" }
      position { 4 }
    end

    factory :type_milestone do
      name { "Milestone" }
      # Do not hard-code position: acts_as_list + Type.order(:position) would otherwise
      # make this type sort before sequenced types (e.g. type_task) and become
      # project.enabled_types.first / factory fallbacks.
      is_milestone { true }
    end
  end
end
