module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # This strategy is inserted after optional basic auth strategies to
        # indicate that invalid basic auth credentials were provided.
        class BasicAuthFailure < ::Warden::Strategies::BasicAuth

          def valid?
            OpenProject::Configuration.apiv3_enable_basic_auth? && super
          end

          def authenticate_user(_username, _password)
            nil # always fails
          end
        end
      end
    end
  end
end
