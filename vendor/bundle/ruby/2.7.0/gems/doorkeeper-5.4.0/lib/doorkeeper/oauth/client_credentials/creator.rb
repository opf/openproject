# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module ClientCredentials
      class Creator
        def call(client, scopes, attributes = {})
          existing_token = nil

          if lookup_existing_token?
            existing_token = find_existing_token_for(client, scopes)
            return existing_token if server_config.reuse_access_token && existing_token&.reusable?
          end

          with_revocation(existing_token: existing_token) do
            server_config.access_token_model.find_or_create_for(
              application: client,
              resource_owner: nil,
              scopes: scopes,
              **attributes,
            )
          end
        end

        private

        def with_revocation(existing_token:)
          if existing_token && server_config.revoke_previous_client_credentials_token?
            existing_token.with_lock do
              raise Errors::DoorkeeperError, :invalid_token_reuse if existing_token.revoked?

              existing_token.revoke

              yield
            end
          else
            yield
          end
        end

        def lookup_existing_token?
          server_config.reuse_access_token || server_config.revoke_previous_client_credentials_token?
        end

        def find_existing_token_for(client, scopes)
          server_config.access_token_model.matching_token_for(client, nil, scopes)
        end

        def server_config
          Doorkeeper.config
        end
      end
    end
  end
end
