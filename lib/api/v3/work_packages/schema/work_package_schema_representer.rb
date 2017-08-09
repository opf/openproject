#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          class << self
            def represented_class
              WorkPackage
            end

            def create_class(work_package_schema)
              injector_class = ::API::V3::Utilities::CustomFieldInjector
              injector_class.create_schema_representer(work_package_schema,
                                                       WorkPackageSchemaRepresenter)
            end

            def create(work_package_schema, self_link, context)
              create_class(work_package_schema).new(work_package_schema, self_link, context)
            end

            def attribute_group(property)
              lambda do
                key = property.to_s.gsub /^customField/, "custom_field_"
                represented.attribute_group_map key
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
            @action = context.delete(:action) || :update
            super(schema, self_link, context)
          end

          def cache_key
            custom_fields = represented.project.all_work_package_custom_fields

            OpenProject::Cache::CacheKey.key('api/v3/work_packages/schemas',
                                             "#{represented.project.id}-#{represented.type.id}",
                                             I18n.locale,
                                             represented.type.updated_at,
                                             OpenProject::Cache::CacheKey.expand(custom_fields))
          end

          link :baseSchema do
            { href: @base_schema_link } if @base_schema_link
          end

          property :attribute_groups,
                   type: "[]String",
                   as: "_attributeGroups"

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
                 required: false

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
                                     if @action == :create
                                       api_v3_paths.available_projects_on_create
                                     else
                                       api_v3_paths.available_projects_on_edit(represented.id)
                                     end
                                   }

          # TODO:
          # * create an available_work_package_parent resource
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
        end
      end
    end
  end
end
