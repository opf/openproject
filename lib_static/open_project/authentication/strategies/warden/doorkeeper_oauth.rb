require "doorkeeper/grape/authorization_decorator"

module OpenProject
  module Authentication
    module Strategies
      module Warden
        class DoorkeeperOAuth < ::Warden::Strategies::Base
          include FailWithHeader

          # The strategy is supposed to handle bearer tokens that are not JWT.
          # These tokens are issued by OpenProject
          def valid?
            access_token = ::Doorkeeper::OAuth::Token
                             .from_request(decorated_request, *Doorkeeper.configuration.access_token_methods)
            
            # No access token found, so invalid strategy.
            return false if access_token.blank?
            
            # We don't want JWT as our OAuth Bearer token
            JWT.decode(access_token, nil, false)
            false
          rescue JWT::DecodeError
            true
          end

          def authenticate!
            access_token = ::Doorkeeper::OAuth::Token.authenticate(decorated_request,
                                                                   *Doorkeeper.configuration.access_token_methods)
            return fail_with_header!(error: "invalid_token") if access_token.blank?
            return fail_with_header!(error: "invalid_token") if access_token.expired? || access_token.revoked?
            return fail_with_header!(error: "insufficient_scope") if !access_token.includes_scope?(scope)

            if access_token.resource_owner_id.nil?
              user_id = ::Doorkeeper::Application
                          .where(id: access_token.application_id)
                          .where.not(client_credentials_user_id: nil)
                          .pick(:client_credentials_user_id)
              authenticate_user(user_id) if user_id
            else
              authenticate_user(access_token.resource_owner_id)
            end
          end

          private

          def authenticate_user(id)
            user = User.find_by(id:)
            if user
              success!(user)
            else
              fail_with_header!(error: "invalid_token")
            end
          end

          def decorated_request
            @decorated_request ||= ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
          end
        end
      end
    end
  end
end
