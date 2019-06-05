require 'warden/basic_auth'

module OpenProject
  module Authentication
    module Strategies
      module Warden
        # Intended to be used as the last strategy in warden so that the
        # anonymous user is returned if no other strategy applies
        class AnonymousFallback < ::Warden::Strategies::BasicAuth
          def self.configuration
            @configuration ||= {}
          end

          def self.user
            User.anonymous
          end

          def username
            nil
          end

          def password
            nil
          end

          ##
          # Always valid unless session based. We are using it as a fallback after all.
          def valid?
            !session
          end

          def authenticate_user(_username, _password)
            self.class.user
          end

          private

          def session
            env['rack.session']
          end
        end
      end
    end
  end
end
