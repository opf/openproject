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
# frozen_string_literal: true

require "set"

module Screens
  # The fields a work package of a (project, type) must fill on create, and that F03 therefore
  # wants placed on the create screen. Fields with a default are excluded: they fill themselves.
  module RequiredSet
    BATCH_SIZE = 500
    MAX_PROJECTS = 5000

    module_function

    def for(project, type)
      return [] if type.nil?

      keys = Set.new(["subject"])
      variant = project&.type_variant(type)
      keys.merge(Array(variant&.required_attributes).map(&:to_s))

      custom_fields = project ? project.all_work_package_custom_fields.to_a : []
      keys.merge(custom_fields.select(&:is_required).map { |field| "custom_field_#{field.id}" })

      config, f02_defaults = field_rules_for(project, type)
      keys.merge(config.select(&:required).map(&:key))
      defaults = native_defaults | Array(f02_defaults)

      (keys - defaults).to_a
    end

    def for_scheme_type(scheme, type)
      project_ids = ProjectScreenScheme.where(scheme_id: scheme.id).pluck(:project_id)
      return {} if project_ids.empty?
      return :skipped if project_ids.size > MAX_PROJECTS
      return {} if type.nil?

      project_ids.each_slice(BATCH_SIZE).reduce({}) do |acc, batch|
        acc.merge(batch_required(batch, type))
      end
    end

    def query_count_bounded?
      true
    end

    def native_defaults
      @native_defaults ||= TypeVariant
                           .all_work_package_form_attributes
                           .select { |_, meta| meta[:has_default] }
                           .keys
                           .to_set
    end

    def reset_cache!
      @native_defaults = nil
    end

    def field_rules_for(project, type)
      return [[], []] unless defined?(::FieldRules::Resolver)

      config = ::FieldRules::Resolver.for(project, type)
      [config, config.select { |field| field.default_value.present? }.map(&:key)]
    rescue StandardError
      [[], []]
    end

    def batch_required(project_ids, type)
      default_variant = type.default_variant
      pt_variant = ProjectType.where(project_id: project_ids, type_id: type.id)
                              .pluck(:project_id, :variant_id)
                              .to_h
      variant_ids = (pt_variant.values.compact + [default_variant.id]).uniq
      variants = TypeVariant.where(id: variant_ids).index_by(&:id)
      variant_required = variants.transform_values { |variant| Array(variant.required_attributes).map(&:to_s) }

      custom_fields = active_custom_fields(project_ids)
      f02 = field_rules_many(project_ids, type)

      project_ids.index_with do |project_id|
        variant = variants[pt_variant[project_id] || default_variant.id] || default_variant
        keys = Set.new(["subject"])
        keys.merge(variant_required[variant.id] || [])
        keys.merge(custom_fields.fetch(project_id, {}).filter_map { |id, meta| "custom_field_#{id}" if meta[:required] })

        config = f02[[project_id, type.id]]
        defaults = native_defaults.dup
        if config
          keys.merge(config.select(&:required).map(&:key))
          defaults.merge(config.filter_map { |field| field.key if field.default_value.present? })
        end
        defaults.merge(custom_fields.fetch(project_id, {}).filter_map { |id, meta| "custom_field_#{id}" if meta[:default] })

        (keys - defaults).to_a
      end
    end

    def active_custom_fields(project_ids)
      rows = WorkPackageCustomField
             .joins(:projects)
             .where(projects: { id: project_ids })
             .pluck("projects.id", :id, :is_required, :default_value)
      rows.each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |(project_id, id, required, default_value), acc|
        acc[project_id][id] = { required:, default: default_value.present? }
      end
    end

    def field_rules_many(project_ids, type)
      return {} unless defined?(::FieldRules::Resolver)

      ::FieldRules::Resolver.for_many(project_ids, [type.id])
    rescue StandardError
      {}
    end
  end
end
