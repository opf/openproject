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

##
# Implements the deletion of a user.
module Users
  class DeleteService < ::BaseServices::Delete
    ##
    # Deletes the given user if allowed.
    #
    # @return True if the user deletion has been initiated, false otherwise.
    def destroy(user_object)
      # as destroying users is a lengthy process we handle it in the background
      # and mark the account as deleted now so that no action can be performed with it
      # don't use "deleted!" handle as it will raise on invalid users
      user_object.update_column(:status, User.statuses[:deleted])
      ::Principals::DeleteJob.perform_later(user_object)

      logout! if self_delete?

      true
    end

    private

    def self_delete?
      user == model
    end

    def logout!
      User.current = nil
    end
  end
end
