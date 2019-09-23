require 'doorkeeper/grape/authorization_decorator'

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Allows testing authentication via doorkeeper OAuth2 token
        #
        class DoorkeeperOAuth < ::Warden::Strategies::Base
          def valid?
            @token = ::Doorkeeper::OAuth::Token.authenticate(decorated_request, *Doorkeeper.configuration.access_token_methods)
            @token&.accessible? && @token.acceptable?(scope)
          end

          def authenticate!
            if @token.resource_owner_id.nil?
              authenticate_client_credentials(@token)
            else
              authenticate_user(@token.resource_owner_id)
            end
          end

          private

          ##
          # We allow applications to designate a user to be used for client credentials.
          # When using client credentials flow, find this user and try to authenticate
          def authenticate_client_credentials(token)
            if client_credential_user = find_credential_app_user(token.application_id)
              authenticate_user client_credential_user
            else
              success! User.anonymous
            end
          end

          ##
          # Find a credentials-enabled application with the given ID
          # and return its allowed application user, if there is one.
          # Avoid going through token.application.client_credentials_user_id for performance
          # (this is going to be called on every request with CC flows!)
          def find_credential_app_user(app_id)
            ::Doorkeeper::Application
              .where(id: app_id)
              .where.not(client_credentials_user_id: nil)
              .pluck(:client_credentials_user_id)
              .first
          end

          def authenticate_user(id)
            user = User.find_by(id: id)
            if user
              success!(user)
            else
              fail!("No such user")
            end
          end

          def decorated_request
            ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
          end
        end
      end
    end
  end
end
