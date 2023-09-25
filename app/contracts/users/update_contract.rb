#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Users
  class UpdateContract < BaseContract
    validate :user_allowed_to_update

    ##
    # Users can only be updated when
    # - the user is editing herself
    # - the user is an admin
    # - the user has the global manage_user permission and is not editing an admin
    def allowed_to_update?
      editing_themself? || can_manage_user?
    end

    private

    def user_allowed_to_update
      unless allowed_to_update?
        errors.add :base, :error_unauthorized
      end
    end

    def editing_themself?
      user == model
    end

    # Only admins can edit other admins
    # Only users with manage_user permission can edit other users
    def can_manage_user?
      user.allowed_to_globally?(:manage_user) && (user.admin? || !model.admin?)
    end
  end
end
