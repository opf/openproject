# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module OAuthConfigurations
      class NextcloudConfiguration
        attr_reader :oauth_client

        def initialize(storage)
          @uri = storage.uri
          @oauth_client = storage.oauth_client.freeze
        end

        def authorization_state_check(token)
          util = StorageInteraction::Nextcloud::Util
          response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
            http.get(
              util.join_uri_path(@uri, '/ocs/v1.php/cloud/user'),
              {
                'Authorization' => "Bearer #{token}",
                'OCS-APIRequest' => 'true',
                'Accept' => 'application/json'
              }
            )
          end

          case response
          when Net::HTTPSuccess
            :success
          when Net::HTTPForbidden, Net::HTTPUnauthorized
            :refresh_needed
          else
            :error
          end
        end

        def compute_scopes(scopes)
          scopes
        end

        def basic_rack_oauth_client
          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            secret: @oauth_client.client_secret,
            scheme: @uri.scheme,
            host: @uri.host,
            port: @uri.port,
            authorization_endpoint: File.join(@uri.path, "/index.php/apps/oauth2/authorize"),
            token_endpoint: File.join(@uri.path, "/index.php/apps/oauth2/api/v1/token")
          )
        end
      end
    end
  end
end
