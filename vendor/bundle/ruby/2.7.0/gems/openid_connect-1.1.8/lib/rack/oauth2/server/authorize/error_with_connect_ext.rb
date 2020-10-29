module Rack
  module OAuth2
    module Server
      class Authorize
        module ErrorWithConnectExt
          DEFAULT_DESCRIPTION = {
            invalid_redirect_uri: 'The redirect_uri in the request does not match any of pre-registered redirect_uris.',
            interaction_required: 'End-User interaction required.',
            login_required: 'End-User authentication required.',
            session_selection_required: 'The End-User is required to select a session at the Authorization Server.',
            consent_required: 'End-User consent required.',
            invalid_request_uri: 'The request_uri in the request returns an error or invalid data.',
            invalid_openid_request_object: 'The request parameter contains an invalid OpenID Request Object.'
          }

          def self.included(klass)
            DEFAULT_DESCRIPTION.each do |error, default_description|
              # NOTE:
              #  Connect Message spec doesn't say anything about HTTP status code for each error code.
              #  It probably means "use 400".
              error_method = :bad_request!
              klass.class_eval <<-ERROR
                def #{error}!(description = "#{default_description}", options = {})
                  #{error_method} :#{error}, description, options
                end
              ERROR
            end
          end
        end
        Request.send :include, ErrorWithConnectExt
      end
    end
  end
end