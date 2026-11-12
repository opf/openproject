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

module Storages
  class SharepointStorage < Storage
    IDENTIFIER_SEPARATOR = ":"

    PROVIDER_FIELDS_DEFAULTS = {
      automatically_managed: false,
      automatic_management_enabled: false,
      managed_drive_name: "OpenProject"
    }.freeze

    store_attribute :provider_fields, :tenant_id, :string
    store_attribute :provider_fields, :managed_drive_id, :string
    store_attribute :provider_fields, :managed_drive_name, :string

    def self.allowed_by_enterprise_token?
      EnterpriseToken.allows_to?(:one_drive_sharepoint_file_storage)
    end

    def self.short_provider_name = :sharepoint

    def self.non_confidential_provider_fields
      super + %i[tenant_id]
    end

    def audience = nil

    def authenticate_via_idp? = false

    def authenticate_via_storage? = true

    def available_project_folder_modes
      if automatic_management_enabled?
        ProjectStorage.project_folder_modes.keys
      else
        %w[inactive manual]
      end
    end

    def uri
      @uri ||= URI("https://graph.microsoft.com").normalize
    end

    def connect_src
      host_uri = URI(host)
      ["#{host_uri.scheme}://#{host_uri.host}"]
    end

    def oauth_configuration = Adapters::Providers::Sharepoint::OAuthConfiguration.new(self)

    def provider_fields_defaults
      PROVIDER_FIELDS_DEFAULTS
    end

    def automatic_management_new_record?
      if provider_fields_changed?
        previous_configuration = provider_fields_change.first
        previous_configuration.values_at("automatically_managed").compact.empty?
      else
        automatic_management_unspecified?
      end
    end

    def configuration_checks
      {
        storage_oauth_client_configured: oauth_client.present?,
        storage_redirect_uri_configured: oauth_client&.persisted?,
        storage_tenant_drive_configured: tenant_id.present?,
        access_management_configured: !automatic_management_unspecified?,
        name_configured: name.present?
      }
    end
  end
end
