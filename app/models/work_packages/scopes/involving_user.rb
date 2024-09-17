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
#

module WorkPackages::Scopes
  module InvolvingUser
    extend ActiveSupport::Concern

    class_methods do
      # Fetches all work packages for which a user is assigned to, responsible
      # for, or watcher, via a group or themself
      #
      # @param user User the user involved in work packages.
      def involving_user(user)
        WorkPackage.left_joins(:watchers)
          .where(watchers: { user: })
          .or(WorkPackage.where(assigned_to: user))
          .or(WorkPackage.where(assigned_to: group_having(user)))
          .or(WorkPackage.where(responsible: user))
          .or(WorkPackage.where(responsible: group_having(user)))
      end

      private

      def group_having(user)
        GroupUser.select(:group_id).where(user_id: user.id)
      end
    end
  end
end
