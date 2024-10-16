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

class MigrateOidcSettingsToProviders < ActiveRecord::Migration[7.1]
  def up
    providers = Hash(Setting.plugin_openproject_openid_connect).with_indifferent_access[:providers]
    return if providers.blank?

    providers.each do |name, configuration|
      migrate_provider!(name, configuration)
    end
  end

  def down
    # This migration does not yet remove Setting.plugin_openproject_openid_connect
    # so it can be retried.
  end

  private

  def migrate_provider!(name, configuration)
    Rails.logger.debug { "Trying to migrate OpenID provider #{name} from previous settings format..." }
    call = ::OpenIDConnect::SyncService.new(name, configuration).call

    if call.success
      Rails.logger.debug { <<~SUCCESS }
        Successfully migrated OpenID provider #{name} from previous settings format.
        You can now manage this provider in the new administrative UI within OpenProject under
        the "Administration -> Authentication -> OpenID providers" section.
      SUCCESS
    else
      raise <<~ERROR
        Failed to create or update OpenID provider #{name} from previous settings format.
        The error message was: #{call.message}

        Please check the logs for more information and open a bug report in our community:
        https://www.openproject.org/docs/development/report-a-bug/

        If you would like to skip migrating the OpenID provider setting and discard them instead, you can use our documentation
        to unset any previous OpenID provider settings:

        https://www.openproject.org/docs/system-admin-guide/authentication/openid-providers/
      ERROR
    end
  end
end
