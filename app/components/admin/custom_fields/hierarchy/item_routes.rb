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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CustomFields
    module Hierarchy
      module ItemRoutes
        private

        def custom_field
          raise SubclassResponsibilityError
        end

        def hierarchy_items_path
          item_route_helpers.public_send(:"#{item_route_prefix}custom_field_items_path", custom_field.id)
        end

        def hierarchy_item_path(item, action = nil, **)
          hierarchy_item_route(:path, item, action, **)
        end

        def hierarchy_item_url(item, action = nil, **)
          hierarchy_item_route(:url, item, action, **)
        end

        def hierarchy_item_route(type, item, action, **)
          name = [action, "#{item_route_prefix}custom_field_item", type].compact.join("_")
          item_route_helpers.public_send(name, custom_field.id, item, **)
        end

        def item_route_prefix
          case custom_field
          when ProjectCustomField then "admin_settings_project_"
          when UserCustomField then "admin_settings_user_"
          else ""
          end
        end

        def item_route_helpers = self
      end
    end
  end
end
