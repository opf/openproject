#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

##
# Implements the deletion of a user.
module Users
  class DeleteService
    attr_reader :user, :actor

    def initialize(user, actor)
      @user = user
      @actor = actor
    end

    ##
    # Deletes the given user if allowed.
    #
    # @return True if the user deletion has been initiated, false otherwise.
    def call
      if deletion_allowed?
        # as destroying users is a lengthy process we handle it in the background
        # and lock the account now so that no action can be performed with it
        user.lock!
        DeleteUserJob.perform_later(user)

        logout! if self_delete?

        true
      else
        false
      end
    end

    ##
    # Checks if a given user may be deleted by another one.
    #
    # @param user [User] User to be deleted.
    # @param actor [User] User who wants to delete the given user.
    def self.deletion_allowed?(user, actor)
      if actor == user
        Setting.users_deletable_by_self?
      else
        actor.admin? && actor.active? && Setting.users_deletable_by_admins?
      end
    end

    private

    def deletion_allowed?
      self.class.deletion_allowed? user, actor
    end

    def self_delete?
      user == actor
    end

    def logout!
      User.current = nil
    end
  end
end
