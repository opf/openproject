module Warden
  module Strategies
    ##
    # This strategy is inserted after optional basic auth strategies to
    # indicate that invalid basic auth credentials were provided.
    class BasicAuthFailure < BasicAuth
      def authenticate_user(_username, _password)
        nil # always fails
      end
    end
  end
end
