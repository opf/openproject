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

module LdapGroups
  class SynchronizationJob < ::Cron::CronJob
    # Run every 30 minutes
    self.cron_expression = '*/30 * * * *'

    def perform
      return unless EnterpriseToken.allows_to?(:ldap_groups)

      User.system.run_given do
        synchronize!
      end
    end

    private

    def synchronize!
      LdapAuthSource.find_each do |ldap|
        Rails.logger.info { "[LDAP groups] Retrieving groups from filters for ldap auth source #{ldap.name}" }
        LdapGroups::SynchronizedFilter
          .where(auth_source_id: ldap.id)
          .find_each { |filter| OpenProject::LdapGroups::SynchronizeFilter.new(filter) }

        Rails.logger.info { "[LDAP groups] Start group synchronization for ldap auth source #{ldap.name}" }
        OpenProject::LdapGroups::Synchronization.new(ldap)
      end
    rescue StandardError => e
      msg = "[LDAP groups] Failed to run LDAP group synchronization. #{e.class.name}: #{e.message}"
      Rails.logger.error msg
    end
  end
end