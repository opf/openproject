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

module Ldap
  class BaseService
    attr_reader :ldap

    def initialize(ldap)
      @ldap = ldap
    end

    def call
      User.system.run_given do
        OpenProject::Mutex.with_advisory_lock_transaction(ldap, self.class.name) do
          perform
        end
      end
    end

    def perform
      raise SubclassResponsibilityError
    end

    protected

    def synchronize_user(user, ldap_con)
      Rails.logger.debug { "[LDAP user sync] Synchronizing user #{user.login}." }

      update_attributes = user_attributes(user.login, ldap_con)
      synchronize_user_attributes(user, update_attributes)
    end

    def synchronize_user_attributes(user, attributes)
      if attributes.blank?
        lock_user!(user)
      elsif user.new_record?
        try_to_create(attributes)
      else
        try_to_update(user, attributes)
      end
    end

    # Try to create the user from attributes
    def try_to_update(user, attrs)
      call = Users::UpdateService
        .new(model: user, user: User.system)
        .call(attrs.merge(ldap_auth_source_id: ldap.id))

      if call.success?
        activate_user!(user)
        Rails.logger.info { "[LDAP user sync] User '#{call.result.login}' updated." }
      else
        Rails.logger.error { "[LDAP user sync] User '#{user.login}' could not be updated: #{call.message}" }
      end

      call
    end

    def try_to_create(attrs)
      call = Users::CreateService
        .new(user: User.system)
        .call(attrs.merge(ldap_auth_source_id: ldap.id))

      if call.success?
        Rails.logger.info { "[LDAP user sync] User '#{call.result.login}' created." }
      else
        # Ensure contract errors are merged into the user
        call.result.errors.merge! call.errors
        Rails.logger.error { "[LDAP user sync] User '#{attrs[:login]}' could not be created: #{call.message}" }
      end

      call
    end

    ##
    # Locks the given user if this is what the sync service should do.
    def lock_user!(user)
      if OpenProject::Configuration.ldap_users_sync_status?
        Rails.logger.info { "Could not find user #{user.login} in #{ldap.name}. Locking the user." }
        user.update_column(:status, Principal.statuses[:locked])
      else
        Rails.logger.info do
          "Could not find user #{user.login} in #{ldap.name}. Ignoring due to ldap_users_sync_status being unset"
        end
      end
    end

    ##
    # Activates the given user if this is what the sync service should do.
    def activate_user!(user)
      if OpenProject::Configuration.ldap_users_sync_status?
        Rails.logger.info { "Activating #{user.login} due to it being synced from LDAP #{ldap.name}." }
        user.update_column(:status, Principal.statuses[:active])
      elsif !user.active?
        Rails.logger.info do
          "Would activate #{user.login} through #{ldap.name} but ignoring due to ldap_users_sync_status being unset."
        end
      end
    end

    ##
    # Get the user attributes of a single matching LDAP entry.
    #
    # If the login matches multiple entries, return nil and issue a warning.
    # If the login does not match, returns nil
    def user_attributes(login, ldap_con)
      # Return the first matching user
      entries = find_entries_by(login:, ldap_con:)

      if entries.count == 0
        Rails.logger.info { "[LDAP user sync] Did not find LDAP entry for #{login}" }
        return
      end

      if entries.count > 1
        Rails.logger.warn { "[LDAP user sync] Found multiple entries for #{login}: #{entries.map(&:dn)}. Skipping" }
        return
      end

      entries.first
    end

    def find_entries_by(login:, ldap_con: new_ldap_connection)
      ldap_con
        .search(
          base: ldap.base_dn,
          filter: ldap.login_filter(login),
          attributes: ldap.search_attributes
        )
        &.map { |entry| ldap.get_user_attributes_from_ldap_entry(entry).except(:dn) } || []
    end

    def new_ldap_connection
      ldap.instance_eval { initialize_ldap_con(account, account_password) }
    end
  end
end
