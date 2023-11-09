# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class NextcloudStorage < Storage
    PROVIDER_FIELDS_DEFAULTS = {
      automatically_managed: true,
      username: 'OpenProject'
    }.freeze

    store_attribute :provider_fields, :automatically_managed, :boolean
    store_attribute :provider_fields, :username, :string
    store_attribute :provider_fields, :password, :string
    store_attribute :provider_fields, :group, :string
    store_attribute :provider_fields, :group_folder, :string

    scope :automatically_managed, -> { where("provider_fields->>'automatically_managed' = 'true'") }

    def oauth_configuration
      Peripherals::OAuthConfigurations::NextcloudConfiguration.new(self)
    end

    def automatic_management_unspecified?
      automatically_managed.nil?
    end

    def configuration_checks
      {
        storage_oauth_client_configured: oauth_client.present?,
        openproject_oauth_application_configured: oauth_application.present?,
        host_name_configured: host.present? && name.present?
      }
    end

    %i[username group group_folder].each do |attribute_method|
      define_method(attribute_method) do
        super().presence || PROVIDER_FIELDS_DEFAULTS[:username]
      end
    end

    def mark_as_unhealthy(reason: nil)
      return true if unhealthy?

      update(health_status: :unhealthy, health_changed_at: Time.now.utc, health_reason: reason)
    end

    def mark_as_healthy
      return true if unhealthy?

      update(health_status: :ok, health_changed_at: Time.now.utc, health_reason: nil)
    end

    def healthy?
      health_status == 'ok'
    end

    def unhealthy?
      not healthy?
    end

    def provider_fields_defaults
      PROVIDER_FIELDS_DEFAULTS
    end
  end
end
