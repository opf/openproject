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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Workspaces
      module WorkspaceRepresenterFactory
        module_function

        def create_link_lambda(name, property_name: name)
          ->(*) {
            project_link(represented.public_send(name),
                         name: property_name,
                         getter: :id)
          }
        end

        def create_setter_lambda(name, namespaces: %i(projects programs portfolios workspaces))
          ->(fragment:, **) {
            href = fragment["href"]

            break if href == API::V3::URN_UNDISCLOSED

            if href
              id = ::API::Utilities::ResourceLinkParser.parse_id(
                href,
                property: name,
                expected_version: "3",
                expected_namespace: namespaces
              )

              # In case an identifier is provided, which might
              # start with numbers, the id needs to be looked up
              # in the DB.
              id = if id.to_i.to_s == id
                     id.to_i # return numerical ID
                   else
                     Project.where(identifier: id).pick(:id) # lookup Project by identifier
                   end

              represented.public_send("#{name}_id=", id) if id
            else
              represented.public_send("#{name}_id=", nil)
            end
          }
        end
      end
    end
  end
end
