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
            user = User.where(id: @token.resource_owner_id).first
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
