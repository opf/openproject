module Rack
  module OAuth2
    class AccessToken
      class Authenticator
        def initialize(token)
          @token = token
        end

        # Callback called in HTTPClient (before sending a request)
        # request:: HTTP::Message
        def filter_request(request)
          @token.authenticate(request)
        end

        # Callback called in HTTPClient (after received a response)
        # response:: HTTP::Message
        # request::  HTTP::Message
        def filter_response(response, request)
          # nothing to do
        end
      end
    end
  end
end