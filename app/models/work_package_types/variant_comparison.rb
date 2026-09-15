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

module WorkPackageTypes
  # Every variant of a type, side by side. The base variant leads, so each column reads against
  # the configuration the type itself carries.
  class VariantComparison
    FORM = TypeVariant::FORM_CONFIGURATION
    WORKFLOWS = TypeVariant::WORKFLOWS

    # Named by the tab that configures each one, so the rows carry the labels an administrator
    # already navigates by.
    ASPECT_LABEL_KEYS = {
      TypeVariant::DEFAULTS => "types.edit.defaults.tab",
      FORM => "types.edit.form_configuration.tab",
      WORKFLOWS => "types.edit.workflow.tab",
      TypeVariant::PROJECT_ATTRIBUTES => "types.edit.project_attributes.tab",
      TypeVariant::PDF_EXPORT => "types.edit.export_configuration.tab"
    }.freeze

    SECTIONS = %i[scope configuration form workflows].freeze

    EMPTY_WORKFLOW = { status_ids: [], role_ids: [], transitions: [] }.freeze

    def initialize(type:)
      @type = type
    end

    attr_reader :type

    def columns = profiles

    def any_variants? = profiles.many?

    def rows_of(section) = rows.select { it.section == section }

    def sections = SECTIONS.map { [it, rows_of(it)] }.reject { |_, list| list.empty? }

    def cell(profile, row)
      Cell.new(row:, profile:, values: row.values_of(profile), same_as_base: same_as_base(profile, row))
    end

    def duplicates_of(profile)
      duplicate_groups.fetch(profile.digest, []).reject { it.id == profile.id }
    end

    private

    def rows
      @rows ||= scope_rows + configuration_rows + form_rows + workflow_rows
    end

    def configuration_rows
      ASPECT_LABEL_KEYS.map do |aspect, label_key|
        Row.new(section: :configuration, key: aspect, aspect:, label_key:,
                reader: ->(_) { [] }, format: :mode)
      end
    end

    def scope_rows
      %i[availability enabled_in_new_projects projects].map do |key|
        Row.new(section: :scope, key:, aspect: nil, label_key: "types.comparison.rows.scope.#{key}",
                reader: ->(_) { [] }, format: :plain)
      end
    end

    # Nil where the question does not apply: on any other row, and on the base variant itself.
    def same_as_base(profile, row)
      return if row.format != :same_as_base || profile.base? || base_profile.nil?

      profile.digest_for(row.aspect) == base_profile.digest_for(row.aspect)
    end

    def base_profile = @base_profile ||= profiles.find(&:base?)

    def form_rows
      [same_as_base_row(:form, FORM),
       row(:form, :groups, FORM, :group_names),
       row(:form, :fields, FORM, :builtin_fields),
       row(:form, :custom_fields, FORM, :custom_fields),
       row(:form, :required, FORM, :required),
       row(:form, :excluded, FORM, :excluded)]
    end

    def workflow_rows
      [same_as_base_row(:workflows, WORKFLOWS),
       row(:workflows, :statuses, WORKFLOWS, :statuses),
       row(:workflows, :transitions, WORKFLOWS, :transitions),
       row(:workflows, :roles, WORKFLOWS, :roles)]
    end

    def same_as_base_row(section, aspect)
      Row.new(section:, key: :same_as_base, aspect:,
              label_key: "types.comparison.rows.#{section}.same_as_base",
              reader: ->(_) { [] }, format: :same_as_base)
    end

    def row(section, key, aspect, reader)
      Row.new(section:, key:, aspect:, label_key: "types.comparison.rows.#{section}.#{key}",
              reader: ->(profile) { profile.public_send(reader) }, format: :count)
    end

    def duplicate_groups
      @duplicate_groups ||= profiles.group_by(&:digest).select { |_, group| group.many? }
    end

    def profiles
      @profiles ||= variants.map { build_profile(it) }
    end

    def variants
      @variants ||= type.variants
                        .with_effective_source(FORM)
                        .with_effective_source(WORKFLOWS)
                        .includes(:project)
                        .in_display_order
                        .to_a
    end

    def build_profile(variant)
      Profile.new(variant:, project_count: project_counts.fetch(variant.id, 0),
                  **form_of(variant), **workflow_of(variant))
    end

    def form_of(variant)
      {
        fields: field_set.for(variant),
        required: variant.required_attributes.map { field_set.field_for(it) },
        group_names: variant.attribute_groups.map(&:translated_key),
        excluded: excluded_fields(variant)
      }
    end

    def workflow_of(variant)
      workflow = workflows_by_owner.fetch(variant.effective_source_id(WORKFLOWS), EMPTY_WORKFLOW)

      {
        statuses: workflow[:status_ids].filter_map { statuses[it] }.sort_by(&:position),
        transitions: workflow[:transitions],
        roles: workflow[:role_ids].filter_map { roles[it] }.sort_by(&:name)
      }
    end

    def excluded_fields(variant)
      state = ExclusionState.for(variant, FORM)
      return [] if state.nil?

      state.effective.map { field_set.field_for(it) }
    end

    def field_set
      @field_set ||= FormFieldSet.new
    end

    def workflows_by_owner
      @workflows_by_owner ||= begin
        owner_ids = variants.map { it.effective_source_id(WORKFLOWS) }.uniq

        ::Workflow.where(type_variant_id: owner_ids)
                  .pluck(:type_variant_id, :role_id, :old_status_id, :new_status_id)
                  .group_by(&:first)
                  .transform_values { |list| summarize_transitions(list) }
      end
    end

    def summarize_transitions(list)
      {
        status_ids: list.flat_map { [it[2], it[3]] }.uniq,
        role_ids: list.pluck(1).uniq,
        transitions: list.map { it.drop(1) }
      }
    end

    def statuses
      @statuses ||= ::Status.where(id: workflows_by_owner.values.flat_map { it[:status_ids] }.uniq).index_by(&:id)
    end

    def roles
      @roles ||= ::Role.where(id: workflows_by_owner.values.flat_map { it[:role_ids] }.uniq).index_by(&:id)
    end

    def project_counts
      @project_counts ||= ::ProjectType.where(variant_id: variants.map(&:id)).group(:variant_id).count
    end
  end
end
