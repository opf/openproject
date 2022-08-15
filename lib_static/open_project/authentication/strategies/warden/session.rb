require 'open_project/authentication/session_expiry'

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Temporary strategy necessary as long as the OpenProject authentication has
        # not been unified in terms of Warden strategies and is only locally
        # applied to the API v3.
        class Session < ::Warden::Strategies::Base
          include ::OpenProject::Authentication::SessionExpiry

          def valid?
            # A session must exist and valid
            return false if session.nil? || session_ttl_expired?

            # We allow GET requests on the API session
            # without headers (e.g., for images on attachments)
            return true if request.get?

            # For all other requests, to mitigate CSRF vectors,
            # require the frontend header to be present.
            xml_request_header_set?
          end

          def authenticate!
            user = user_id ? User.find(user_id) : User.anonymous

            success! user
          end

          def xml_request_header_set?
            request.env['HTTP_X_REQUESTED_WITH'.freeze] == 'XMLHttpRequest'.freeze
          end

          def user_id
            Hash(session)['user_id']
          end

          def session
            env['rack.session']
          end
        end
      end
    end
  end
end
