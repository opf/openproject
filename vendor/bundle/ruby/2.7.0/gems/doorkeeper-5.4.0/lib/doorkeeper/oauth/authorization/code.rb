# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Authorization
      class Code
        attr_reader :pre_auth, :resource_owner, :token

        def initialize(pre_auth, resource_owner)
          @pre_auth = pre_auth
          @resource_owner = resource_owner
        end

        def issue_token!
          return @token if defined?(@token)

          @token = Doorkeeper.config.access_grant_model.create!(access_grant_attributes)
        end

        def oob_redirect
          { action: :show, code: token.plaintext_token }
        end

        private

        def authorization_code_expires_in
          Doorkeeper.config.authorization_code_expires_in
        end

        def access_grant_attributes
          attributes = {
            application_id: pre_auth.client.id,
            expires_in: authorization_code_expires_in,
            redirect_uri: pre_auth.redirect_uri,
            scopes: pre_auth.scopes.to_s,
          }

          if Doorkeeper.config.polymorphic_resource_owner?
            attributes[:resource_owner] = resource_owner
          else
            attributes[:resource_owner_id] = resource_owner.id
          end

          pkce_attributes.merge(attributes)
        end

        def pkce_attributes
          return {} unless pkce_supported?

          {
            code_challenge: pre_auth.code_challenge,
            code_challenge_method: pre_auth.code_challenge_method,
          }
        end

        # Ensures firstly, if migration with additional PKCE columns was
        # generated and migrated
        def pkce_supported?
          Doorkeeper.config.access_grant_model.pkce_supported?
        end
      end
    end
  end
end
