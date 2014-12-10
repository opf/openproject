#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
      module Form
        class WorkPackageSchemaRepresenter < Roar::Decorator
          include Roar::JSON::HAL
          include Roar::Hypermedia
          include API::V3::Utilities::PathHelper

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          def initialize(model, options = {})
            @current_user = options[:current_user]

            super(model)
          end

          property :_type,
                   getter: -> (*) { { type: 'MetaType', required: true, writable: false } },
                   writeable: false
          property :lock_version,
                   getter: -> (*) { { type: 'Integer', required: true, writable: false } },
                   writeable: false
          property :subject,
                   getter: -> (*) { { type: 'String' } },
                   writeable: false
          property :description,
                   getter: -> (*) { { type: 'Formattable' } },
                   writeable: false
          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     status_origin = represented

                     if represented.persisted? && represented.status_id_changed?
                       status_origin = represented.class.find(represented.id)
                     end

                     status_origin.new_statuses_allowed_to(@current_user)
                   } do
            include Roar::JSON::HAL

            self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

            property :links_to_allowed_statuses,
                     as: :_links,
                     getter: -> (*) { self } do
              include API::V3::Utilities::PathHelper

              self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

              property :allowed_values, exec_context: :decorator

              def allowed_values
                represented.map do |status|
                  { href: api_v3_paths.status(status.id), title: status.name }
                end
              end
            end

            property :type, getter: -> (*) { 'Status' }

            collection :allowed_values,
                       embedded: true,
                       class: ::Status,
                       decorator: ::API::V3::Statuses::StatusRepresenter,
                       getter: -> (*) { self }
          end

          property :assignee, getter: -> (*) { self } do
            include Roar::JSON::HAL

            self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

            property :links_to_available_assignees,
                     as: :_links,
                     getter: -> (*) { self } do
              include API::V3::Utilities::PathHelper

              self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

              property :allowed_values,
                       getter: -> (*) {
                         { href: api_v3_paths.available_assignees(represented.project.id) }
                       },
                       exec_context: :decorator
            end

            property :type, getter: -> (*) { 'User' }
          end

          property :responsible, getter: -> (*) { self } do
            include Roar::JSON::HAL

            self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

            property :links_to_available_responsibles,
                     as: :_links,
                     getter: -> (*) { self } do
              include API::V3::Utilities::PathHelper

              self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

              property :allowed_values,
                       getter: -> (*) {
                         { href: api_v3_paths.available_responsibles(represented.project.id) }
                       },
                       exec_context: :decorator
            end

            property :type, getter: -> (*) { 'User' }
          end
        end
      end
    end
  end
end
