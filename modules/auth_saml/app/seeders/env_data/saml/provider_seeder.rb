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
        Setting.seed_saml_provider.each do |name, options|
          print_status "    ↳ Creating or Updating SAML provider #{name}" do
            provider = ::Saml::Provider.find_by(slug: name)
            params = ::Saml::ConfigurationMapper.new(options).call!
            params["options"]["seeded_from_env"] = true

            if provider
              print_status "   - Updating existing SAML provider '#{name}' from ENV"
              update(name, provider, params)
            else
              print_status "   - Creating new SAML provider '#{name}' from ENV"
              create(name, params)
            end
          end
        end
      end

      def applicable?
        Setting.seed_saml_provider.present?
      end

      private

      def create(name, params)
        ::Saml::Providers::CreateService
          .new(user: User.system)
          .call(params)
          .on_success { print_status "   - Successfully saved SAML provider #{name}." }
          .on_failure { |call| raise "Failed to create SAML provider: #{call.message}" }
      end

      def update(name, provider, params)
        ::Saml::Providers::UpdateService
          .new(model: provider, user: User.system)
          .call(params)
          .on_success { print_status "   - Successfully updated SAML provider #{name}." }
          .on_failure { |call| raise "Failed to update SAML provider: #{call.message}" }
      end
    end
  end
end
