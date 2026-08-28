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

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

          include API::Caching::CachedRepresenter

          # type_variant is part of the key on top of type: the configuration in force changes
          # when the project resolves the family to a different variant, which touches neither
          # the project's nor the type's timestamp.
          cached_representer key_parts: %i[project type type_variant],
                             dependencies: -> {
                               all_permissions_granted_to_user_under_project +
                                 [Setting.work_package_done_ratio,
                                  Setting::WorkPackageMultipleVersions.active?]
                             }

          custom_field_injector type: :schema_representer

          class << self
            def represented_class
              WorkPackage
            end

            def attribute_group(property)
              lambda do
                key = property.to_s.gsub /^customField/, "custom_field_"
                attribute_group_map key
              end
            end

            # override the various schema methods to include

            def schema(property, *args)
              opts, = args
              opts[:attribute_group] = attribute_group property

              super(property, **opts)
            end

            def schema_with_allowed_link(property, *args)
              opts, = args
              opts[:attribute_group] = attribute_group property

              super(property, **opts)
            end

            def schema_with_allowed_collection(property, *args)
              opts, = args
              opts[:attribute_group] = attribute_group property

              super(property, **opts)
            end
          end

          def initialize(schema, self_link:, **context)
            @base_schema_link = context.delete(:base_schema_link) || nil
            @show_lock_version = !context.delete(:hide_lock_version)
            super
          end

          link :baseSchema do
            { href: @base_schema_link } if @base_schema_link
          end

          link :attachments do
            next if represented.work_package.hide_attachments?

            { href: nil }
          end

          # Needs to not be cached as the queries in the attribute
          # groups might contain information (e.g. project names) whose
          # visibility needs to be checked per user
          property :attribute_groups,
                   type: "[]String",
                   as: "_attributeGroups",
                   exec_context: :decorator,
                   uncacheable: true

          schema :lock_version,
                 type: "Integer",
                 show_if: ->(*) { @show_lock_version }

          schema :id,
                 type: "Integer"

          schema :subject,
                 type: "String",
                 min_length: 1,
                 max_length: 255,
                 has_default: -> {
                   represented.type_variant&.replacement_pattern_defined_for?(:subject)
                 },
                 placeholder: -> {
                   if represented.type_variant&.replacement_pattern_defined_for?(:subject)
                     I18n.t("placeholders.templated_hint", type: represented.type_variant.name)
                   end
                 }

          schema :description,
                 type: "Formattable",
                 required: false

          schema :duration,
                 type: "Duration",
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :schedule_manually,
                 type: "Boolean",
                 required: false,
                 has_default: true

          schema :ignore_non_working_days,
                 type: "Boolean",
                 required: false

          schema :start_date,
                 type: "Date",
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :due_date,
                 type: "Date",
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :derived_start_date,
                 type: "Date",
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :derived_due_date,
                 type: "Date",
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :date,
                 type: "Date",
                 required: false,
                 show_if: ->(*) { represented.milestone? }

          schema :estimated_time,
                 type: "Duration",
                 required: false

          schema :derived_estimated_time,
                 name_source: ->(*) { I18n.t("attributes.derived_estimated_hours") },
                 type: "Duration",
                 required: false

          schema :remaining_time,
                 name_source: :remaining_hours,
                 type: "Duration",
                 required: false,
                 writable: ->(*) { WorkPackage.work_based_mode? }

          schema :derived_remaining_time,
                 name_source: :derived_remaining_hours,
                 type: "Duration",
                 required: false,
                 writable: false

          schema :spent_time,
                 type: "Duration",
                 required: false,
                 show_if: ->(*) {
                   current_user.allowed_in_project?(:view_time_entries, represented.project) ||
                     current_user.allowed_in_any_work_package?(:view_own_time_entries, in_project: represented.project)
                 }

          schema :percentage_done,
                 type: "Integer",
                 name_source: :done_ratio,
                 required: false

          schema :derived_percentage_done,
                 type: "Integer",
                 name_source: :derived_done_ratio,
                 required: false

          schema :readonly,
                 type: "Boolean",
                 show_if: ->(*) { Status.can_readonly? },
                 required: false,
                 has_default: true

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          schema :author,
                 type: "User",
                 location: :link,
                 writable: false

          schema_with_allowed_link :project,
                                   type: "Project",
                                   required: true,
                                   href_callback: ->(*) {
                                     work_package = represented.work_package
                                     if work_package&.new_record?
                                       api_v3_paths.available_projects_on_create
                                     else
                                       api_v3_paths.available_projects_on_edit(represented.id)
                                     end
                                   }

          schema_with_allowed_collection :project_phase,
                                         value_representer: ProjectPhases::ProjectPhaseRepresenter,
                                         link_factory: ->(phase) {
                                           {
                                             href: api_v3_paths.project_phase(phase.id),
                                             title: phase.name
                                           }
                                         },
                                         required: false,
                                         show_if: ->(*) {
                                           current_user.allowed_in_project?(:view_project_phases, represented.project) &&
                                             represented.assignable_project_phases.any?
                                         },
                                         writable: -> { represented.writable?(:project_phase_definition_id) }

          schema_with_allowed_link :parent,
                                   type: "WorkPackage",
                                   required: false,
                                   writable: true,
                                   href_callback: ->(*) {
                                     work_package = represented.work_package
                                     if work_package&.persisted?
                                       api_v3_paths.work_package_available_relation_candidates(represented.id, type: :parent)
                                     end
                                   }

          schema_with_allowed_link :assignee,
                                   type: "User",
                                   required: false,
                                   href_callback: ->(*) { assignee_user_autocompleter }

          schema_with_allowed_link :responsible,
                                   type: "User",
                                   required: false,
                                   href_callback: ->(*) { assignee_user_autocompleter }

          schema_with_allowed_link :risk_owner,
                                   type: "User",
                                   required: false,
                                   href_callback: ->(*) { assignee_user_autocompleter }

          schema :risk_likelihood,
                 type: "Decimal",
                 required: false

          schema :risk_impact,
                 type: "Decimal",
                 required: false

          schema :risk_exposure,
                 type: "Decimal",
                 required: false,
                 writable: false

          schema :risk_response,
                 type: "String",
                 required: false

          schema :risk_category_ids,
                 type: "[]Integer",
                 required: false

          schema_with_allowed_collection :type,
                                         value_representer: Types::TypeRepresenter,
                                         link_factory: ->(type) {
                                           {
                                             href: api_v3_paths.type(type.id),
                                             title: type.name
                                           }
                                         },
                                         has_default: false

          schema_with_allowed_collection :status,
                                         value_representer: Statuses::StatusRepresenter,
                                         link_factory: ->(status) {
                                           {
                                             href: api_v3_paths.status(status.id),
                                             title: status.name
                                           }
                                         },
                                         has_default: true

          schema_with_allowed_collection :category,
                                         value_representer: Categories::CategoryRepresenter,
                                         link_factory: ->(category) {
                                           {
                                             href: api_v3_paths.category(category.id),
                                             title: category.name
                                           }
                                         },
                                         required: false

          # Deprecated in favour of `targetVersions`
          # Removed from the API if multiple_versions is enabled on the instance
          schema_with_allowed_collection :version,
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: ->(version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         required: false,
                                         deprecated: true,
                                         # writes through to target_versions, so it is writable when target_versions are.
                                         writable: ->(*) { represented.writable?(:target_versions) },
                                         show_if: ->(*) { !Setting::WorkPackageMultipleVersions.active? },
                                         description: -> { I18n.t("api_v3.attributes.version.deprecated") }

          # While multiple versions is not enabled, the field keeps the label of the
          # single-valued version field it replaces and announces via options.multiple
          # that the UI must restrict it to a single value.
          schema_with_allowed_collection :target_versions,
                                         type: "[]Version",
                                         name_source: -> {
                                           attribute = Setting::WorkPackageMultipleVersions.active? ? :target_versions : :version
                                           WorkPackage.human_attribute_name(attribute)
                                         },
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: ->(version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         writable: ->(*) { represented.writable?(:target_versions) },
                                         required: false,
                                         options: -> { { multiple: Setting::WorkPackageMultipleVersions.active? } }

          schema_with_allowed_collection :observed_in_versions,
                                         type: "[]Version",
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: ->(version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         writable: ->(*) { represented.writable?(:observed_in_versions) },
                                         required: false

          schema_with_allowed_collection :priority,
                                         value_representer: Priorities::PriorityRepresenter,
                                         link_factory: ->(priority) {
                                           {
                                             href: api_v3_paths.priority(priority.id),
                                             title: priority.name
                                           }
                                         },
                                         required: true,
                                         has_default: true

          schema_with_allowed_collection :budget,
                                         type: "Budget",
                                         required: false,
                                         value_representer: ::API::V3::Budgets::BudgetRepresenter,
                                         link_factory: ->(budget) {
                                           {
                                             href: api_v3_paths.budget(budget.id),
                                             title: budget.subject
                                           }
                                         },
                                         show_if: ->(*) {
                                           current_user.allowed_in_project?(:view_budgets, represented.project)
                                         }

          def attribute_groups
            (represented.type_variant&.attribute_groups || []).map do |group|
              if group.is_a?(Type::QueryGroup)
                form_config_query_representation(group)
              else
                form_config_attribute_representation(group)
              end
            end
          end

          ##
          # Return a map of attribute => group name
          def attribute_group_map(key)
            return nil if represented.type_variant.nil?

            @attribute_group_map ||= represented.type_variant.attribute_groups.each_with_object({}) do |group, hash|
              Array(group.active_members(represented.project)).each { |prop| hash[prop] = group.translated_key }
            end

            @attribute_group_map[key]
          end

          private

          def no_caching?
            represented.no_caching?
          end

          protected

          # We do not want to make the represented a part of the cache key
          # as they are currently dynamically created and thus will
          # change their to_params value consistently
          def json_key_part_represented
            []
          end

          def form_config_query_representation(group)
            # While we cannot cache the query group to be shared with other users (e.g. project names)
            # we can cache it for the same user for this request so that when a collection of
            # schemas is rendered, we can reuse that.
            RequestStore.fetch("wp_schema_query_group/#{group.key}") do
              ::JSON::parse(::API::V3::WorkPackages::Schema::FormConfigurations::QueryRepresenter
                              .new(group, current_user:, embed_links: true)
                              .to_json)
            end
          end

          def form_config_attribute_representation(group)
            OpenProject::Cache.fetch_request_cached(*form_config_attribute_cache_key(group)) do
              ::JSON::parse(::API::V3::WorkPackages::Schema::FormConfigurations::AttributeRepresenter
                              .new(group, current_user:, project: represented.project, embed_links: true)
                              .to_json)
            end
          end

          def form_config_attribute_cache_key(group)
            ["wp_schema_attribute_group",
             group.key,
             I18n.locale,
             represented.project,
             represented.type_variant,
             represented.available_custom_fields.sort_by(&:id)]
              .flatten
              .compact
          end

          def all_permissions_granted_to_user_under_project
            Role
              .joins(:members)
              .where(members: { project_id: represented.project, principal: User.current })
              .map(&:permissions)
              .flatten
              .uniq
              .sort
          end

          def assignee_user_autocompleter
            work_package = represented.work_package

            if work_package&.persisted?
              api_v3_paths.available_assignees_in_work_package(represented.id)
            elsif work_package&.project
              api_v3_paths.available_assignees_in_workspace(represented.project_id)
            end
          end
        end
      end
    end
  end
end
