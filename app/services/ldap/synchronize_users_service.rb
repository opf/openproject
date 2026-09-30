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
  class SynchronizeUsersService < BaseService
    attr_reader :logins

    def initialize(ldap, logins = nil)
      super(ldap)
      @logins = logins
    end

    private

    def perform
      ldap_con = new_ldap_connection

      applicable_users.find_each do |user|
        synchronize_user(user, ldap_con)
      rescue ::LdapAuthSource::Error => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name} due to LDAP error: #{e.message}" }
        # Reset the LDAP connection
        ldap_con = new_ldap_connection
      rescue StandardError => e
        Rails.logger.error { "Failed to synchronize user #{ldap.name}: #{e.message}" }
      end
    end

    # Get the applicable users
    # as the service can be called with just a subset of users
    # from rake/external services.
    def applicable_users
      if logins.present?
        ldap.users.where("LOWER(login) in (?)", logins.map(&:downcase))
      else
        ldap.users
      end
    end
  end
end
