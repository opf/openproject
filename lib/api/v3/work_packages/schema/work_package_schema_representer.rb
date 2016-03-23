#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      module Schema
        class WorkPackageSchemaRepresenter < ::API::Decorators::Schema
          class << self
            def represented_class
              WorkPackage
            end

            def create_class(work_package_schema)
              injector_class = ::API::V3::Utilities::CustomFieldInjector
              injector_class.create_schema_representer(work_package_schema,
                                                       WorkPackageSchemaRepresenter)
            end

            def create(work_package_schema, context)
              create_class(work_package_schema).new(work_package_schema, context)
            end
          end

          def initialize(schema, context)
            @self_link = context.delete(:self_link) || nil
            @show_lock_version = !context.delete(:hide_lock_version)
            super(schema, context)
          end

          link :self do
            { href: @self_link } if @self_link
          end

          schema :lock_version,
                 type: 'Integer',
                 name_source: -> (*) { I18n.t('api_v3.attributes.lock_version') },
                 show_if: -> (*) { @show_lock_version }

          schema :id,
                 type: 'Integer'

          schema :subject,
                 type: 'String',
                 min_length: 1,
                 max_length: 255

          schema :description,
                 type: 'Formattable'

          schema :start_date,
                 type: 'Date',
                 required: false

          schema :due_date,
                 type: 'Date',
                 required: false

          schema :estimated_time,
                 type: 'Duration',
                 required: false

          schema :spent_time,
                 type: 'Duration',
                 show_if: -> (_) do
                   current_user_allowed_to(:view_time_entries, context: represented.project)
                 end,
                 required: false

          schema :percentage_done,
                 type: 'Integer',
                 name_source: :done_ratio,
                 show_if: -> (*) { Setting.work_package_done_ratio != 'disabled' },
                 required: false

          schema :created_at,
                 type: 'DateTime'

          schema :updated_at,
                 type: 'DateTime'

          schema :author,
                 type: 'User'

          schema_with_allowed_link :project,
                                   type: 'Project',
                                   required: true,
                                   href_callback: -> (*) {
                                     api_v3_paths.available_projects_on_edit(represented.id)
                                   }

          schema :parent_id,
                 type: 'Integer',
                 required: false,
                 writable: true

          # TODO:
          # * remove parent_id above in favor of only having :parent
          # * create an available_work_package_parent resource
          # * turn :parent into a schema_with_allowed_link

          schema :parent,
                 type: 'WorkPackage',
                 required: false,
                 writable: true

          schema_with_allowed_link :assignee,
                                   type: 'User',
                                   required: false,
                                   href_callback: -> (*) {
                                     api_v3_paths.available_assignees(represented.project.id)
                                   }

          schema_with_allowed_link :responsible,
                                   type: 'User',
                                   required: false,
                                   href_callback: -> (*) {
                                     api_v3_paths.available_responsibles(represented.project.id)
                                   }

          schema_with_allowed_collection :type,
                                         value_representer: Types::TypeRepresenter,
                                         link_factory: -> (type) {
                                           {
                                             href: api_v3_paths.type(type.id),
                                             title: type.name
                                           }
                                         }

          schema_with_allowed_collection :status,
                                         value_representer: Statuses::StatusRepresenter,
                                         link_factory: -> (status) {
                                           {
                                             href: api_v3_paths.status(status.id),
                                             title: status.name
                                           }
                                         }

          schema_with_allowed_collection :category,
                                         value_representer: Categories::CategoryRepresenter,
                                         link_factory: -> (category) {
                                           {
                                             href: api_v3_paths.category(category.id),
                                             title: category.name
                                           }
                                         },
                                         required: false

          schema_with_allowed_collection :version,
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: -> (version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         required: false

          schema_with_allowed_collection :priority,
                                         value_representer: Priorities::PriorityRepresenter,
                                         link_factory: -> (priority) {
                                           {
                                             href: api_v3_paths.priority(priority.id),
                                             title: priority.name
                                           }
                                         }
        end
      end
    end
  end
end
