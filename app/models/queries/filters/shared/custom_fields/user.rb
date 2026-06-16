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

require_relative "list_optional"

module Queries::Filters::Shared
  module CustomFields
    class User < ListOptional
      ##
      # User CFs may reference the 'me' value, so use the values helpers
      # from the Me mixin, which will override the ListOptional value_objects definition.
      include ::Queries::WorkPackages::Filter::MeValueFilterMixin

      def allowed_values
        @allowed_values ||= me_allowed_value + super
      end

      def values_replaced
        vals = super
        vals += group_members_added(vals)
        vals + user_groups_added(vals)
      end

      def autocomplete_options
        {
          component: "opce-user-autocompleter",
          hideSelected: true,
          defaultData: false,
          placeholder: I18n.t(:label_user_search),
          resource: "principals",
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
          filters: [
            { name: "status", operator: "!", values: [Principal.statuses["locked"].to_s] }
          ],
          searchKey: "any_name_attribute",
          focusDirectly: false
        }
      end

      private

      def group_members_added(vals)
        ::User
          .joins(:groups)
          .where(groups_users: { id: vals })
          .pluck(:id)
          .map(&:to_s)
      end

      def user_groups_added(vals)
        Group
          .joins(:users)
          .where(users_users: { id: vals })
          .pluck(:id)
          .map(&:to_s)
      end
    end
  end
end
