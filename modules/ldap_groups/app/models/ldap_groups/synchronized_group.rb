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

require "net/ldap"
require "net/ldap/dn"

module LdapGroups
  class SynchronizedGroup < ApplicationRecord
    belongs_to :group

    belongs_to :ldap_auth_source

    belongs_to :filter,
               class_name: "::LdapGroups::SynchronizedFilter"

    has_many :users,
             class_name: "::LdapGroups::Membership",
             dependent: :delete_all,
             foreign_key: "group_id"

    validates_presence_of :dn
    validates_presence_of :group
    validates_associated :group
    validates_presence_of :ldap_auth_source

    before_destroy :remove_all_members

    ##
    # Add a set of new members to the synchronized group as well as the internal group.
    #
    # @param new_users [Array<User> | Array<Integer>] Users (or User IDs) to add to the group.
    def add_members!(new_users)
      return if new_users.empty?

      self.class.transaction do
        # create synchronized group memberships
        memberships = new_users.to_a.map { |user| { group_id: id, user_id: user_id(user) } }
        # Bulk insert the memberships to improve performance
        ::LdapGroups::Membership.insert_all memberships, unique_by: %i[user_id group_id]

        # add users to users collection of internal group
        add_members_to_group(new_users)
      end
    end

    ##
    # Remove a set of users from the synchronized group as well as the internal group.
    #
    # @param users_to_remove [Array<User> | Array<Integer>] Users (or User IDs) to remove from the group.
    def remove_members!(users_to_remove)
      return if users_to_remove.empty?

      user_ids = users_to_remove.map(&method(:user_id))

      self.class.transaction do
        # 1) Delete synchronized group MEMBERSHIPS from collection.
        users.delete users.where(user_id: user_ids).select(:id)

        # 2) Remove users from the internal group
        remove_members_from_group(user_ids)
      end
    end

    private

    def user_id(user)
      case user
      when Integer
        user
      when User
        user.id
      else
        raise ArgumentError, "Expected User or User ID (Integer) but got #{user}"
      end
    end

    def remove_all_members
      remove_members! users.pluck(:user_id)
    end

    # rubocop:disable Metrics/AbcSize
    def add_members_to_group(new_users)
      user_ids = new_users.map { |user| user_id(user) }

      call = Groups::UpdateService
        .new(user: User.current, model: group)
        .call(add_user_ids: user_ids)

      call.on_success do
        Rails.logger.debug "[LDAP groups] Added users #{user_ids} to #{group.name}"
      end

      call.on_failure do
        Rails.logger.error "[LDAP groups] Failed to add users #{user_ids} to #{group.name}: #{call.message}"
        raise ActiveRecord::Rollback
      end
    end

    def remove_members_from_group(user_ids)
      call = Groups::UpdateService
        .new(user: User.system, model: group)
        .call(remove_user_ids: user_ids)

      call.on_success do
        Rails.logger.debug "[LDAP groups] Removed users #{user_ids} from #{group.name}"
      end

      call.on_failure do
        Rails.logger.error "[LDAP groups] Failed to remove users #{user_ids} from #{group.name}: #{call.message}"
        raise ActiveRecord::Rollback
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
