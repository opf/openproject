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
      module Form
        class WorkPackageAttributeLinksRepresenter < Roar::Decorator
          include Roar::JSON::HAL
          include Roar::Hypermedia
          include API::V3::Utilities::PathHelper

          self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

          def self.linked_property(property_name: nil,
                                   namespace: nil,
                                   method: nil,
                                   path: nil)

            property property_name,
                     exec_context: :decorator,
                     getter: -> (*) {
                       get_path(get_method: method,
                                path: path)
                     },
                     setter: -> (value, *) {
                       parse_link(property: property_name,
                                  namespace: namespace,
                                  value: value,
                                  setter_method: :"#{method}=")
                     }
          end

          linked_property(property_name: :status,
                          namespace: :statuses,
                          method: :status_id,
                          path: :status)

          linked_property(property_name: :assignee,
                          namespace: :users,
                          method: :assigned_to_id,
                          path: :user)

          linked_property(property_name: :responsible,
                          namespace: :users,
                          method: :responsible_id,
                          path: :user)

          linked_property(property_name: :version,
                          namespace: :versions,
                          method: :fixed_version_id,
                          path: :version)

          private

          def get_path(get_method: nil, path: nil)
            id = represented.send(get_method)

            { href: (api_v3_paths.send(path, id) if id) }
          end

          def parse_link(property: nil, namespace: nil, value: {}, setter_method: nil)
            return unless value.has_key?('href')
            resource = parse_resource(property, namespace, value['href'])

            represented.send(setter_method, resource)
          end

          def parse_resource(property, ns, href)
            return nil unless href

            resource = ::API::Utilities::ResourceLinkParser.parse href

            if resource.nil? || resource[:ns] != ns.to_s
              actual_ns = resource ? resource[:ns] : nil

              fail ::API::Errors::Form::InvalidResourceLink.new(property, ns, actual_ns)
            end

            resource ? resource[:id] : nil
          end

        end
      end
    end
  end
end
