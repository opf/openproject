#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module PlaceholderUsers
  class DeleteContract < ::DeleteContract
    delete_permission -> {
      self.class.deletion_allowed?(model, user)
    }

    ##
    # Checks if a given placeholder user may be deleted by a user.
    #
    # @param actor [User] User who wants to delete the given placeholder user.
    def self.deletion_allowed?(placeholder_user,
                               actor,
                               user_allowed_service = Authorization::UserAllowedService.new(actor))
      actor.allowed_to_globally?(:manage_placeholder_user) &&
        affected_projects_managed_by_actor?(placeholder_user, user_allowed_service)
    end

    protected

    def self.affected_projects_managed_by_actor?(placeholder_user, user_allowed_service)
      placeholder_user.projects.active.empty? ||
        user_allowed_service.call(:manage_members, placeholder_user.projects.active).result
    end

    def deletion_allowed?
      self.class.deletion_allowed?(model, user)
    end
  end
end
