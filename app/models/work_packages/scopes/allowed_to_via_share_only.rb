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

module WorkPackages::Scopes
  module AllowedToViaShareOnly
    extend ActiveSupport::Concern

    class_methods do
      # Work packages +user+ holds +permission+ on through a share, i.e. a membership on the
      # work package itself. Membership of the surrounding project grants nothing here, so
      # the result is the shares alone, whether or not that project is visible.
      #
      # The membership relation joins no users table, so the user's state has to be checked
      # here for a locked or deleted user's shares not to keep granting access.
      #
      # @param user User the work packages are shared with.
      # @param permission [Symbol] the permission the share has to grant.
      def allowed_to_via_share_only(user, permission)
        permissions = Authorization.contextual_permissions(permission, :work_package, raise_on_unknown: true)

        return none if user.locked? || user.deleted? || permissions.empty?

        where(id: Project.allowed_to_member_relation(user, permissions, [name]).select(:entity_id))
      end
    end
  end
end
