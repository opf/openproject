#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OpenIDConnect
  class SyncService
    attr_reader :name, :configuration

    def initialize(name, configuration)
      @name = name
      @provider_attributes =
        {
          "slug" => name,
          "oidc_provider" => "custom",
          "display_name" => configuration["display_name"],
          "client_id" => configuration["identifier"],
          "client_secret" => configuration["secret"],
          "issuer" => configuration["issuer"],
          "authorization_endpoint" => configuration["authorization_endpoint"],
          "token_endpoint" => configuration["token_endpoint"],
          "userinfo_endpoint" => configuration["userinfo_endpoint"],
          "end_session_endpoint" => configuration["end_session_endpoint"],
          "jwks_uri" => configuration["jwks_uri"]
        }
    end

    def call
      provider = ::OpenIDConnect::Provider.find_by(slug: name)
      if provider
        ::OpenIDConnect::Providers::UpdateService
          .new(model: provider, user: User.system)
          .call(@provider_attributes)
          .on_success { |call| call.message = "Successfully updated OpenID provider #{name}." }
          .on_failure { |call| call.message = "Failed to update OpenID provider: #{call.message}" }
      else
        ::OpenIDConnect::Providers::CreateService
          .new(user: User.system)
          .call(@provider_attributes)
          .on_success { |call| call.message = "Successfully created OpenID provider #{name}." }
          .on_failure { |call| call.message = "Failed to create OpenID provider: #{call.message}" }
      end
    end
  end
end
