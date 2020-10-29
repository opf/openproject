module Rack
  module OAuth2
    module Server
      class Authorize < Abstract::Handler
        def _call(env)
          request = Request.new(env)
          response_type_for(request).new(&@authenticator)._call(env).finish
        rescue Rack::OAuth2::Server::Abstract::Error => e
          e.finish
        end

        private

        def response_type_for(request)
          response_type = request.params['response_type'].to_s
          case response_type
          when 'code'
            Code
          when 'token'
            Token
          when ''
            request.attr_missing!
          else
            extensions.detect do |extension|
              extension.response_type_for? response_type
            end || request.unsupported_response_type!
          end
        end

        def extensions
          Extension.constants.sort.collect do |key|
            Extension.const_get key
          end
        end

        class Request < Abstract::Request
          include Server::Extension::ResponseMode::AuthorizationRequest

          attr_required :response_type
          attr_optional :redirect_uri, :state
          attr_accessor :verified_redirect_uri

          def initialize(env)
            super
            # NOTE: Raise before redirect_uri is saved not to redirect back to unverified redirect_uri.
            invalid_request! '"client_id" missing' if client_id.blank?
            @redirect_uri = Util.parse_uri(params['redirect_uri']) if params['redirect_uri']
            @response_mode = params['response_mode']
            @state = params['state']
          end

          def verify_redirect_uri!(pre_registered, allow_partial_match = false)
            @verified_redirect_uri = if redirect_uri.present?
              verified = Array(pre_registered).any? do |_pre_registered_|
                if allow_partial_match
                  Util.uri_match?(_pre_registered_, redirect_uri)
                else
                  _pre_registered_.to_s == redirect_uri.to_s
                end
              end
              if verified
                redirect_uri
              else
                invalid_request! '"redirect_uri" mismatch'
              end
            elsif pre_registered.present? && Array(pre_registered).size == 1 && !allow_partial_match
              Array(pre_registered).first
            else
              invalid_request! '"redirect_uri" missing'
            end
            self.verified_redirect_uri.to_s
          end

          def error_params_location
            nil # => All errors are raised immediately and no error response are returned to client.
          end
        end

        class Response < Abstract::Response
          attr_required :redirect_uri
          attr_optional :state, :session_state, :approval

          def initialize(request)
            @state = request.state
            super
          end

          def approved?
            @approval
          end

          def approve!
            @approval = true
          end

          def protocol_params
            {state: state, session_state: session_state}
          end

          def redirect_uri_with_credentials
            Util.redirect_uri(redirect_uri, protocol_params_location, protocol_params)
          end

          def finish
            if approved?
              attr_missing!
              redirect redirect_uri_with_credentials
            end
            super
          end
        end
      end
    end
  end
end

require 'rack/oauth2/server/authorize/code'
require 'rack/oauth2/server/authorize/token'
require 'rack/oauth2/server/authorize/extension'
require 'rack/oauth2/server/authorize/error'
