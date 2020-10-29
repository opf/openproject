module Rack
  module OAuth2
    module Server
      class Authorize
        module ErrorHandler
          def self.included(klass)
            klass.send :attr_accessor, :redirect_uri, :state, :protocol_params_location
          end

          def protocol_params
            super.merge(state: state)
          end

          def redirect?
            redirect_uri.present? &&
            protocol_params_location.present?
          end

          def finish
            if redirect?
              super do |response|
                response.redirect Util.redirect_uri(redirect_uri, protocol_params_location, protocol_params)
              end
            else
              raise self
            end
          end
        end

        class BadRequest < Abstract::BadRequest
          include ErrorHandler
        end

        class ServerError < Abstract::ServerError
          include ErrorHandler
        end

        class TemporarilyUnavailable < Abstract::TemporarilyUnavailable
          include ErrorHandler
        end

        module ErrorMethods
          DEFAULT_DESCRIPTION = {
            invalid_request: "The request is missing a required parameter, includes an unsupported parameter or parameter value, or is otherwise malformed.",
            unauthorized_client: "The client is not authorized to use the requested response type.",
            access_denied: "The end-user or authorization server denied the request.",
            unsupported_response_type: "The requested response type is not supported by the authorization server.",
            invalid_scope: "The requested scope is invalid, unknown, or malformed.",
            server_error: "Internal Server Error",
            temporarily_unavailable: "Service Unavailable"
          }

          def self.included(klass)
            DEFAULT_DESCRIPTION.each do |error, default_description|
              case error
              when :server_error, :temporarily_unavailable
                # NOTE: defined below
              else
                klass.class_eval <<-ERROR
                  def #{error}!(description = "#{default_description}", options = {})
                    bad_request! :#{error}, description, options
                  end
                ERROR
              end
            end
          end

          def bad_request!(error = :bad_request, description = nil, options = {})
            error! BadRequest, error, description, options
          end

          def server_error!(description = DEFAULT_DESCRIPTION[:server_error], options = {})
            error! ServerError, :server_error, description, options
          end

          def temporarily_unavailable!(description = DEFAULT_DESCRIPTION[:temporarily_unavailable], options = {})
            error! TemporarilyUnavailable, :temporarily_unavailable, description, options
          end

          private

          def error!(klass, error, description, options)
            exception = klass.new error, description, options
            exception.protocol_params_location = error_params_location
            exception.state = state
            exception.redirect_uri = verified_redirect_uri
            raise exception
          end
        end

        Request.send :include, ErrorMethods
      end
    end
  end
end
