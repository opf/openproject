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

module API
  module V3
    module PlaceholderUsers
      class PlaceholderUserRepresenter < ::API::V3::Principals::PrincipalRepresenter
        link :updateImmediately,
             cache_if: -> { current_user_can_manage? } do
          {
            href: api_v3_paths.placeholder_user(represented.id),
            title: "Update #{represented.name}",
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user_can_manage? } do
          {
            href: api_v3_paths.placeholder_user(represented.id),
            title: "Delete #{represented.name}",
            method: :delete
          }
        end

        link :showUser do
          {
            href: api_v3_paths.placeholder_user_path(represented.id),
            type: "text/html"
          }
        end

        property :status,
                 getter: ->(*) { represented.status },
                 setter: ->(fragment:, represented:, **) { represented.status = User.statuses[fragment.to_sym] },
                 exec_context: :decorator,
                 render_nil: true,
                 cache_if: -> { current_user_can_manage? }

        def _type
          "PlaceholderUser"
        end

        def current_user_can_see_date_properties?
          current_user_can_manage?
        end

        def current_user_can_manage?
          current_user&.allowed_globally?(:manage_placeholder_user)
        end
      end
    end
  end
end
