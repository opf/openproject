module Rack
  module OAuth2
    module Server
      module Rails
        REQUEST  = 'rack_oauth2.request'
        RESPONSE = 'rack_oauth2.response'
        ERROR    = 'rack_oauth2.error'
      end
    end
  end
end

require 'rack/oauth2/server/rails/response_ext'
require 'rack/oauth2/server/rails/authorize'
