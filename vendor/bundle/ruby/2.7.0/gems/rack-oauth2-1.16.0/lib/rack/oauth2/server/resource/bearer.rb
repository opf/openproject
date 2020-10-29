module Rack
  module OAuth2
    module Server
      class Resource
        class Bearer < Resource
          def _call(env)
            self.request = Request.new(env)
            super
          end

          private

          class Request < Resource::Request
            def setup!
              tokens = [access_token_in_header, access_token_in_payload].compact
              @access_token = case Array(tokens).size
              when 1
                tokens.first
              else
                invalid_request!('Both Authorization header and payload includes access token.')
              end
              self
            end

            def oauth2?
              (access_token_in_header || access_token_in_payload).present?
            end

            def access_token_in_header
              if @auth_header.provided? && !@auth_header.parts.first.nil? && @auth_header.scheme.to_s == 'bearer'
                @auth_header.params
              else
                nil
              end
            end

            def access_token_in_payload
              params['access_token']
            end
          end
        end
      end
    end
  end
end

require 'rack/oauth2/server/resource/bearer/error'
