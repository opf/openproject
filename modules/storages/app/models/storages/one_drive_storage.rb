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

module Storages
  class OneDriveStorage < Storage
    PROVIDER_FIELDS_DEFAULTS = {
      automatic_management_enabled: true
    }.freeze

    store_attribute :provider_fields, :tenant_id, :string
    store_attribute :provider_fields, :drive_id, :string

    using ::Storages::Peripherals::ServiceResultRefinements

    def configuration_checks
      {
        storage_oauth_client_configured: oauth_client.present?,
        storage_tenant_drive_configured: tenant_id.present? && drive_id.present?,
        access_management_configured: !automatic_management_unspecified?,
        name_configured: name.present?
      }
    end

    def automatic_management_new_record?
      if provider_fields_changed?
        previous_configuration = provider_fields_change.first
        previous_configuration.values_at("automatically_managed").compact.empty?
      else
        automatic_management_unspecified?
      end
    end

    def available_project_folder_modes
      if automatic_management_enabled?
        ["inactive", "automatic"]
      else
        ["inactive", "manual"]
      end
    end

    def oauth_configuration
      Peripherals::OAuthConfigurations::OneDriveConfiguration.new(self)
    end

    def uri
      @uri ||= URI("https://graph.microsoft.com").normalize
    end

    def connect_src
      %w[https://*.sharepoint.com https://*.up.1drv.com]
    end

    def provider_fields_defaults
      PROVIDER_FIELDS_DEFAULTS
    end
  end
end
