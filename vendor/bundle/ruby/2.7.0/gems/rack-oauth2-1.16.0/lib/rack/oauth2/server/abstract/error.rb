module Rack
  module OAuth2
    module Server
      module Abstract
        class Error < StandardError
          attr_accessor :status, :error, :description, :uri, :realm

          def initialize(status, error, description = nil, options = {})
            @status      = status
            @error       = error
            @description = description
            @uri         = options[:uri]
            @realm       = options[:realm]
            super [error, description].compact.join(' :: ')
          end

          def protocol_params
            {
              error:             error,
              error_description: description,
              error_uri:         uri
            }
          end

          def finish
            response = Rack::Response.new
            response.status = status
            yield response if block_given?
            unless response.redirect?
              response.header['Content-Type'] = 'application/json'
              response.write Util.compact_hash(protocol_params).to_json
            end
            response.finish
          end
        end

        class BadRequest < Error
          def initialize(error = :bad_request, description = nil, options = {})
            super 400, error, description, options
          end
        end

        class Unauthorized < Error
          def initialize(error = :unauthorized, description = nil, options = {})
            super 401, error, description, options
          end
        end

        class Forbidden < Error
          def initialize(error = :forbidden, description = nil, options = {})
            super 403, error, description, options
          end
        end

        class ServerError < Error
          def initialize(error = :server_error, description = nil, options = {})
            super 500, error, description, options
          end
        end

        class TemporarilyUnavailable < Error
          def initialize(error = :temporarily_unavailable, description = nil, options = {})
            super 503, error, description, options
          end
        end
      end
    end
  end
end
