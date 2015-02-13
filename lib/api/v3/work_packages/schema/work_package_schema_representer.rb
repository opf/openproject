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

            alias_method :original_new, :new

            # we can't use a factory method as we sometimes rely on ROAR instantiating representers
            # for us. Thus we override the :new method.
            # This allows adding instance specific properties to our representer.
            def new(work_package_schema, context)
              klass = Class.new(WorkPackageSchemaRepresenter)
              injector = ::API::V3::Utilities::CustomFieldInjector.new(klass)
              work_package_schema.available_custom_fields.each do |custom_field|
                injector.inject_schema(custom_field)
              end

              klass.original_new(work_package_schema, context)
            end
          end

          schema :_type,
                 type: 'MetaType',
                 title: I18n.t('api_v3.attributes._type'),
                 writable: false

          schema :lock_version,
                 type: 'Integer',
                 title: I18n.t('api_v3.attributes.lock_version'),
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
                 required: false

          schema :due_date,
                 type: 'Date',
                 required: false

          schema :estimated_time,
                 type: 'Duration',
                 required: false,
                 writable: false

          schema :spent_time,
                 type: 'Duration',
                 writable: false

          schema :percentage_done,
                 type: 'Integer',
                 title: WorkPackage.human_attribute_name(:done_ratio),
                 writable: false

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

          schema :type,
                 type: 'Type',
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

          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     assignable_statuses = represented.assignable_statuses_for(current_user)
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Status',
                       name: WorkPackage.human_attribute_name(:status),
                       current_user: current_user,
                       value_representer: API::V3::Statuses::StatusRepresenter,
                       link_factory: -> (status) {
                         {
                           href: api_v3_paths.status(status.id),
                           title: status.name
                         }
                       })

                     if represented.defines_assignable_values?
                       representer.allowed_values = assignable_statuses
                     end

                     representer
                   }

          property :category,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Category',
                       name: WorkPackage.human_attribute_name(:category),
                       value_representer: API::V3::Categories::CategoryRepresenter,
                       link_factory: -> (category) {
                         {
                           href: api_v3_paths.category(category.id),
                           title: category.name
                         }
                       })

                     representer.required = false

                     if represented.defines_assignable_values?
                       representer.allowed_values = represented.assignable_categories
                     end

                     representer
                   }

          property :version,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Version',
                       name: WorkPackage.human_attribute_name(:version),
                       current_user: current_user,
                       value_representer: API::V3::Versions::VersionRepresenter,
                       link_factory: -> (version) {
                         {
                           href: api_v3_paths.version(version.id),
                           title: version.name
                         }
                       })

                     representer.required = false

                     if represented.defines_assignable_values?
                       representer.allowed_values = represented.assignable_versions
                     end

                     representer
                   }

          property :priority,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: 'Priority',
                       name: WorkPackage.human_attribute_name(:priority),
                       current_user: current_user,
                       value_representer: API::V3::Priorities::PriorityRepresenter,
                       link_factory: -> (priority) {
                         {
                           href: api_v3_paths.priority(priority.id),
                           title: priority.name
                         }
                       })

                     if represented.defines_assignable_values?
                       representer.allowed_values = represented.assignable_priorities
                     end

                     representer
                   }

          def current_user
            context[:current_user]
          end

          def _type
            'MetaType'
          end
        end
      end
    end
  end
end
