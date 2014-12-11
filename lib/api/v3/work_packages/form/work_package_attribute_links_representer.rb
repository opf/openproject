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
        class WorkPackageAttributeLinksRepresenter < Roar::Decorator
          include Roar::JSON::HAL
          include Roar::Hypermedia
          include API::V3::Utilities::PathHelper

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     { href: api_v3_paths.status(represented.status_id) }
                   },
                   setter: -> (value, *) {
                     resource = parse_resource(:status, :statuses, value['href'])

                     represented.status_id = resource[:id] if resource
                   }

          property :assignee,
                   exec_context: :decorator,
                   getter: -> (*) {
                     id = represented.assigned_to_id

                     { href: (api_v3_paths.user(id) if id) }
                   },
                   setter: -> (value, *) {
                     user_id = parse_user_resource(:assignee, value['href'])

                     represented.assigned_to_id = user_id
                   }

          property :responsible,
                   exec_context: :decorator,
                   getter: -> (*) {
                     id = represented.responsible_id

                     { href: (api_v3_paths.user(id) if id) }
                   },
                   setter: -> (value, *) {
                     user_id = parse_user_resource(:responsible, value['href'])

                     represented.responsible_id = user_id
                   }

          private

          def parse_resource(property, ns, href)
            return nil unless href

            resource = ::API::Utilities::ResourceLinkParser.parse href

            if resource.nil? || resource[:ns] != ns.to_s
              actual_ns = resource ? resource[:ns] : nil

              fail ::API::Errors::Form::InvalidResourceLink.new(property, ns, actual_ns)
            end

            resource
          end

          def parse_user_resource(property, href)
            resource = parse_resource(property, :users, href)

            resource ? resource[:id] : nil
          end
        end
      end
    end
  end
end
