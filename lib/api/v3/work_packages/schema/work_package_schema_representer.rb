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

          link :self do
            path = api_v3_paths.work_package_schema(represented.project.id, represented.type.id)

            unless form_embedded
              { href: path }
            end
          end

          schema :lock_version,
                 type: 'Integer',
                 name_source: -> (*) { I18n.t('api_v3.attributes.lock_version') },
                 writable: false

          schema :id,
                 type: 'Integer',
                 writable: false

          schema :subject,
                 type: 'String',
                 min_length: 1,
                 max_length: 255

          schema :description,
                 type: 'Formattable'

          schema :start_date,
                 type: 'Date',
                 required: false,
                 writable: -> { represented.start_date_writable? }

          schema :due_date,
                 type: 'Date',
                 required: false,
                 writable: -> { represented.due_date_writable? }

          schema :estimated_time,
                 type: 'Duration',
                 required: false,
                 writable: -> { represented.estimated_time_writable? }

          schema :spent_time,
                 type: 'Duration',
                 writable: false,
                 show_if: -> (_) do
                   current_user_allowed_to(:view_time_entries, context: represented.project)
                 end

          schema :percentage_done,
                 type: 'Integer',
                 name_source: :done_ratio,
                 writable: -> { represented.percentage_done_writable? },
                 show_if: -> (*) { Setting.work_package_done_ratio != 'disabled' }

          schema :created_at,
                 type: 'DateTime',
                 writable: false

          schema :updated_at,
                 type: 'DateTime',
                 writable: false

          schema :author,
                 type: 'User',
                 writable: false

          schema :project,
                 type: 'Project',
                 writable: false

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
                                         values_callback: -> (*) {
                                           represented.assignable_types
                                         },
                                         value_representer: Types::TypeRepresenter,
                                         link_factory: -> (type) {
                                           {
                                             href: api_v3_paths.type(type.id),
                                             title: type.name
                                           }
                                         }

          schema_with_allowed_collection :status,
                                         values_callback: -> (*) {
                                           represented.assignable_statuses_for(current_user)
                                         },
                                         value_representer: Statuses::StatusRepresenter,
                                         link_factory: -> (status) {
                                           {
                                             href: api_v3_paths.status(status.id),
                                             title: status.name
                                           }
                                         }

          schema_with_allowed_collection :category,
                                         values_callback: -> (*) {
                                           represented.assignable_categories
                                         },
                                         value_representer: Categories::CategoryRepresenter,
                                         link_factory: -> (category) {
                                           {
                                             href: api_v3_paths.category(category.id),
                                             title: category.name
                                           }
                                         },
                                         required: false

          schema_with_allowed_collection :version,
                                         values_callback: -> (*) {
                                           represented.assignable_versions
                                         },
                                         value_representer: Versions::VersionRepresenter,
                                         link_factory: -> (version) {
                                           {
                                             href: api_v3_paths.version(version.id),
                                             title: version.name
                                           }
                                         },
                                         required: false

          schema_with_allowed_collection :priority,
                                         values_callback: -> (*) {
                                           represented.assignable_priorities
                                         },
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
