# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module OAuthConfigurations
      class OneDriveConfiguration
        DEFAULT_SCOPES = %w[offline_access files.readwrite.all user.read sites.readwrite.all].freeze

        attr_reader :oauth_client

        def initialize(storage)
          @storage = storage
          @uri = storage.uri
          @oauth_client = storage.oauth_client
          @oauth_uri = URI('https://login.microsoftonline.com/').normalize
        end

        def authorization_state_check(access_token)
          response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
            http.get('/v1.0/me', { 'Authorization' => "Bearer #{access_token}", 'Accept' => 'application/json' })
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
          Array(scopes) | DEFAULT_SCOPES
        end

        def basic_rack_oauth_client
          Rack::OAuth2::Client.new(
            identifier: @oauth_client.client_id,
            secret: @oauth_client.client_secret,
            scheme: @oauth_uri.scheme,
            host: @oauth_uri.host,
            port: @oauth_uri.port,
            authorization_endpoint: "/#{@storage.tenant_id}/oauth2/v2.0/authorize",
            token_endpoint: "/#{@storage.tenant_id}/oauth2/v2.0/token"
          )
        end
      end
    end
  end
end
