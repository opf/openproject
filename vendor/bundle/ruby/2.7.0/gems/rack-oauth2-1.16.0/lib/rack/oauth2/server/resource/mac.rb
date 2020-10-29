module Rack
  module OAuth2
    module Server
      class Resource
        class MAC < Resource
          def _call(env)
            self.request = Request.new(env)
            super
          end

          private

          class Request < Resource::Request
            attr_reader :nonce, :ts, :ext, :signature

            def setup!
              auth_params = Rack::Auth::Digest::Params.parse(@auth_header.params).with_indifferent_access
              @access_token = auth_params[:id]
              @nonce = auth_params[:nonce]
              @ts = auth_params[:ts]
              @ext = auth_params[:ext]
              @signature = auth_params[:mac]
              self
            end

            def oauth2?
              @auth_header.provided? && @auth_header.scheme.to_s == 'mac'
            end
          end
        end
      end
    end
  end
end

require 'rack/oauth2/server/resource/mac/error'
