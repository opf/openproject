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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module Principals
      class PrincipalRepresenter < ::API::Decorators::Single
        include AvatarHelper
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter

        self_link

        link :memberships,
             cache_if: -> { current_user_allowed_to_see_members? } do
          filters = [
            {
              principal: {
                operator: "=",
                values: [represented.id.to_s]
              }
            }
          ]

          {
            href: api_v3_paths.path_for(:memberships, filters:),
            title: I18n.t(:label_membership_plural)
          }
        end

        property :id,
                 render_nil: true

        property :name,
                 render_nil: true

        date_time_property :created_at,
                           cache_if: -> { current_user_can_see_date_properties? }

        date_time_property :updated_at,
                           cache_if: -> { current_user_can_see_date_properties? }

        def current_user_can_see_date_properties?
          current_user_is_admin_or_self
        end

        def current_user_is_admin_or_self
          current_user_is_admin? || current_user_is_self?
        end

        def current_user_is_admin?
          current_user.admin?
        end

        def current_user_is_self?
          represented.id == current_user.id
        end

        def current_user_allowed_to_see_members?
          current_user.allowed_in_any_project?(:view_members) ||
            current_user.allowed_in_any_project?(:manage_members)
        end
      end
    end
  end
end
