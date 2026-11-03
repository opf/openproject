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

module Notifications::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Return notifications visible to a user:
      # * the user is the recipient
      # * the user has the permission to see the associated resource
      #
      # Notifications exist for work packages and documents. Each resource type is
      # checked against the visibility scope of its own model.
      def visible(user)
        recipient(user)
          .merge(visible_resources(user))
      end

      # The resource types notifications can be visible for, mapped to the scope
      # of resources of that type visible to the user.
      def visible_resource_scopes(user)
        {
          "WorkPackage" => WorkPackage.visible(user),
          "Document" => Document.visible(user)
        }
      end

      private

      # One `resource_type = ... AND resource_id IN (subquery)` condition per resource type,
      # combined by OR. Built on an unscoped relation so that the conditions of the scope
      # `visible` is called on are not repeated within each OR branch.
      def visible_resources(user)
        visible_resource_scopes(user)
          .map { |resource_type, scope| unscoped.where(resource_type:, resource_id: scope.select(:id)) }
          .reduce(:or)
      end
    end
  end
end
