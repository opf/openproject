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
  module Authentication
    module Strategies
      class ClientCredentialsStrategy < OAuthStrategy
        using ::Storages::Peripherals::ServiceResultRefinements

        def initialize(oauth_configuration)
          @oauth_client = oauth_configuration.basic_rack_oauth_client

          super()
        end

        def with_credential(&)
        end

        private

        def request_token(options = {})
          rack_access_token = rack_oauth_client(options).access_token!(:body)

          ServiceResult.success(result: rack_access_token)
        rescue Rack::OAuth2::Client::Error => e
          service_result_with_error(i18n_rack_oauth2_error_message(e), e.message)
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::ParsingError, Faraday::SSLError => e
          service_result_with_error(
            "#{I18n.t('oauth_client.errors.oauth_returned_http_error')}: #{e.class}: #{e.message.to_html}",
            e.message
          )
        rescue StandardError => e
          service_result_with_error(
            "#{I18n.t('oauth_client.errors.oauth_returned_standard_error')}: #{e.class}: #{e.message.to_html}",
            e.message
          )
        end
      end
    end
  end
end
