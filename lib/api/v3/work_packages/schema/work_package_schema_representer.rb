#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

          include API::Caching::CachedRepresenter
          cached_representer key_parts: %i[project type],
                             dependencies: -> {
                               User.current.roles_for_project(represented.project).map(&:permissions).flatten.uniq.sort +
                                 [Setting.work_package_done_ratio]
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

              super property, **opts
            end

            def schema_with_allowed_link(property, *args)
              opts, = args
              opts[:attribute_group] = attribute_group property

              super property, **opts
            end

            def schema_with_allowed_collection(property, *args)
              opts, = args
              opts[:attribute_group] = attribute_group property

              super property, **opts
            end
          end

          def initialize(schema, self_link, context)
            @base_schema_link = context.delete(:base_schema_link) || nil
            @show_lock_version = !context.delete(:hide_lock_version)
            super(schema, self_link, context)
          end

          link :baseSchema do
            { href: @base_schema_link } if @base_schema_link
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
                 type: 'Integer',
                 name_source: ->(*) { I18n.t('api_v3.attributes.lock_version') },
                 show_if: ->(*) { @show_lock_version }

          schema :id,
                 type: 'Integer'

          schema :subject,
                 type: 'String',
                 min_length: 1,
                 max_length: 255

          schema :description,
                 type: 'Formattable',
                 required: false

          schema :schedule_manually,
                 type: 'Boolean',
                 required: false,
                 has_default: true

          schema :start_date,
                 type: 'Date',
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :due_date,
                 type: 'Date',
                 required: false,
                 show_if: ->(*) { !represented.milestone? }

          schema :date,
                 type: 'Date',
                 required: false,
                 show_if: ->(*) { represented.milestone? }

          schema :estimated_time,
                 type: 'Duration',
                 required: false

          schema :spent_time,
                 type: 'Duration',
                 required: false,
                 show_if: ->(*) { represented.project && represented.project.module_enabled?('time_tracking') }

          schema :percentage_done,
                 type: 'Integer',
                 name_source: :done_ratio,
                 show_if: ->(*) { Setting.work_package_done_ratio != 'disabled' },
                 required: false

          schema :created_at,
                 type: 'DateTime'

          schema :updated_at,
                 type: 'DateTime'

          schema :author,
                 type: 'User',
                 writable: false

          schema_with_allowed_link :project,
                                   type: 'Project',
                                   required: true,
                                   href_callback: ->(*) {
                                     work_package = represented.work_package
                                     if work_package&.new_record?
                                       api_v3_paths.available_projects_on_create(work_package.type_id)
                                     else
                                       api_v3_paths.available_projects_on_edit(represented.id)
                                     end
                                   }

          # TODO:
          # * create an available_work_package_parent resource
          #   One can use a relatable filter with the 'parent' operator. Will however need to also
          #   work without a value which is currently not supported.
          # * turn :parent into a schema_with_allowed_link

          schema :parent,
                 type: 'WorkPackage',
                 required: false,
                 writable: true

          schema_with_allowed_link :assignee,
                                   type: 'User',
                                   required: false,
                                   href_callback: ->(*) {
                                     if represented.project
                                       api_v3_paths.available_assignees(represented.project_id)
                                     end
                                   }

          schema_with_allowed_link :responsible,
                                   type: 'User',
                                   required: false,
                                   href_callback: ->(*) {
                                     if represented.project
                                       api_v3_paths.available_responsibles(represented.project_id)
                                     end
                                   }

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

          schema_with_allowed_collection :version,
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: ->(version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         required: false

          schema_with_allowed_collection :priority,
                                         value_representer: Priorities::PriorityRepresenter,
                                         link_factory: ->(priority) {
                                           {
                                             href: api_v3_paths.priority(priority.id),
                                             title: priority.name
                                           }
                                         },
                                         required: false,
                                         has_default: true

          def attribute_groups
            (represented.type&.attribute_groups || []).map do |group|
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
            return nil if represented.type.nil?

            @attribute_group_map ||= begin
              represented.type.attribute_groups.each_with_object({}) do |group, hash|
                Array(group.active_members(represented.project)).each { |prop| hash[prop] = group.translated_key }
              end
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
                              .new(group, current_user: current_user, embed_links: true)
                              .to_json)
            end
          end

          def form_config_attribute_representation(group)
            cache_keys = ['wp_schema_attribute_group',
                          group.key,
                          I18n.locale,
                          represented.project,
                          represented.type,
                          represented.available_custom_fields.sort_by(&:id)]

            OpenProject::Cache.fetch(OpenProject::Cache::CacheKey.expand(cache_keys.flatten.compact)) do
              ::JSON::parse(::API::V3::WorkPackages::Schema::FormConfigurations::AttributeRepresenter
                              .new(group, current_user: current_user, project: represented.project, embed_links: true)
                              .to_json)
            end
          end
        end
      end
    end
  end
end
