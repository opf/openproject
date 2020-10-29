module Rack
  module OAuth2
    module Server
      class Token
        class BadRequest < Abstract::BadRequest
        end

        class Unauthorized < Abstract::Unauthorized
          def finish
            super do |response|
              response.header['WWW-Authenticate'] = 'Basic realm="OAuth2 Token Endpoint"'
            end
          end
        end

        module ErrorMethods
          DEFAULT_DESCRIPTION = {
            invalid_request: "The request is missing a required parameter, includes an unsupported parameter or parameter value, repeats a parameter, includes multiple credentials, utilizes more than one mechanism for authenticating the client, or is otherwise malformed.",
            invalid_client: "The client identifier provided is invalid, the client failed to authenticate, the client did not include its credentials, provided multiple client credentials, or used unsupported credentials type.",
            invalid_grant: "The provided access grant is invalid, expired, or revoked (e.g. invalid assertion, expired authorization token, bad end-user password credentials, or mismatching authorization code and redirection URI).",
            unauthorized_client: "The authenticated client is not authorized to use the access grant type provided.",
            unsupported_grant_type: "The access grant included - its type or another attribute - is not supported by the authorization server.",
            invalid_scope: "The requested scope is invalid, unknown, malformed, or exceeds the previously granted scope."
          }

          def self.included(klass)
            DEFAULT_DESCRIPTION.each do |error, default_description|
              error_method = if error == :invalid_client
                :unauthorized!
              else
                :bad_request!
              end
              klass.class_eval <<-ERROR
                def #{error}!(description = "#{default_description}", options = {})
                  #{error_method} :#{error}, description, options
                end
              ERROR
            end
          end

          def bad_request!(error, description = nil, options = {})
            raise BadRequest.new(error, description, options)
          end

          def unauthorized!(error, description = nil, options = {})
            raise Unauthorized.new(error, description, options)
          end
        end

        Request.send :include, ErrorMethods
      end
    end
  end
end
