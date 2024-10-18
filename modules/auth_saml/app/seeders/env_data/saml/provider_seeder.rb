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
module EnvData
  module Saml
    class ProviderSeeder < Seeder
      def seed_data!
        provider_configuration.each do |name, options|
          print_status "    ↳ Creating or Updating SAML provider #{name}" do
            call = ::Saml::SyncService.new(name, options).call

            if call.success
              print_status "   - #{call.message}"
            else
              raise call.message
            end
          end
        end
      end

      def applicable?
        provider_configuration.present?
      end

      def provider_configuration
        config = Setting.seed_saml_provider
        deprecated_config = load_deprecated_configuration.presence || {}

        config.reverse_merge(deprecated_config)
      end

      private

      def load_deprecated_configuration
        deprecated_settings = Rails.root.join("config/plugins/auth_saml/settings.yml")

        if deprecated_settings.exist?
          Rails.logger.info do
            <<~WARNING
              Loading SAML configuration from deprecated location #{deprecated_settings}.
              Please use ENV variables or UI configuration instead.

              For more information, see our guide on how to configure SAML.
              https://www.openproject.org/docs/system-admin-guide/authentication/saml/
            WARNING
          end

          begin
            YAML::load(File.open(deprecated_settings))&.symbolize_keys
          rescue StandardError
            Rails.logger.error "Failed to load deprecated SAML configuration from #{deprecated_settings}. Ignoring that file."
            nil
          end
        end
      end
    end
  end
end
