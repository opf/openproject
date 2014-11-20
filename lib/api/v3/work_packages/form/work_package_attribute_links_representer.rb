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
          include API::Utilities::UrlHelper

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          property :status,
                   exec_context: :decorator,
                   getter: -> (*) {
                     { href: "#{root_path}api/v3/statuses/#{represented.status.id}" }
                   },
                   setter: -> (value, *) {
                     resource = ::API::V3::Utilities::ResourceLinkParser.parse value['href']

                     represented.status_id = resource[:id] if resource[:ns] == 'statuses'
                   }

          property :assignee,
                   exec_context: :decorator,
                   getter: -> (*) {
                     id = represented.assigned_to_id

                     { href: id ? "#{root_path}api/v3/users/#{id}" : nil }
                   },
                   setter: -> (value, *) {
                     user_id = parse_user_resource(value['href'])

                     represented.assigned_to_id = user_id
                   }

          property :responsible,
                   exec_context: :decorator,
                   getter: -> (*) {
                     id = represented.responsible_id

                     { href: id ? "#{root_path}api/v3/users/#{id}" : nil }
                   },
                   setter: -> (value, *) {
                     user_id = parse_user_resource(value['href'])

                     represented.responsible_id = user_id
                   }

          def parse_user_resource(href)
            return nil unless href

            resource = ::API::V3::Utilities::ResourceLinkParser.parse href

            # The return value -1 will trigger a validation error. This is
            # intended as no valid user resource was passed
            (resource && resource[:ns] == 'users') ? resource[:id] : -1
          end
        end
      end
    end
  end
end
