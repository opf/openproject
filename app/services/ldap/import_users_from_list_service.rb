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

module Ldap
  class ImportUsersFromListService < BaseService
    attr_reader :logins

    def initialize(ldap, logins)
      super(ldap)
      @logins = logins
    end

    def perform
      new_users = logins - existing_users

      Rails.logger.debug { "Importing LDAP user import for #{ldap.name} for #{new_users.count} new users." }
      import! new_users
    end

    def import!(new_users)
      ldap_con = new_ldap_connection

      new_users.each do |login|
        synchronize_user(User.new(login:), ldap_con)
      rescue ::LdapAuthSource::Error => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name} due to LDAP error: #{e.message}" }
        # Reset the LDAP connection
        ldap_con = new_ldap_connection
      rescue StandardError => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name}: #{e.message}" }
      end
    end

    def existing_users
      User.where("LOWER(login) in (?)", logins.map(&:downcase)).pluck(:login)
    end
  end
end
