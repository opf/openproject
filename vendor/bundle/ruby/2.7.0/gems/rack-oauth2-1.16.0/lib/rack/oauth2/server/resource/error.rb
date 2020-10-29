module Rack
  module OAuth2
    module Server
      class Resource
        class BadRequest < Abstract::BadRequest
        end

        class Unauthorized < Abstract::Unauthorized
          def scheme
            raise 'Define me!'
          end

          def finish
            super do |response|
              self.realm ||= DEFAULT_REALM
              header = response.header['WWW-Authenticate'] = "#{scheme} realm=\"#{realm}\""
              if ErrorMethods::DEFAULT_DESCRIPTION.keys.include?(error)
                header << ", error=\"#{error}\""
                header << ", error_description=\"#{description}\"" if description.present?
                header << ", error_uri=\"#{uri}\""                 if uri.present?
              end
            end
          end
        end

        class Forbidden < Abstract::Forbidden
          attr_accessor :scope

          def initialize(error = :forbidden, description = nil, options = {})
            super
            @scope = options[:scope]
          end

          def protocol_params
            super.merge(scope: Array(scope).join(' '))
          end
        end

        module ErrorMethods
          DEFAULT_DESCRIPTION = {
            invalid_request: "The request is missing a required parameter, includes an unsupported parameter or parameter value, repeats the same parameter, uses more than one method for including an access token, or is otherwise malformed.",
            invalid_token: "The access token provided is expired, revoked, malformed or invalid for other reasons.",
            insufficient_scope: "The request requires higher privileges than provided by the access token."
          }

          def self.included(klass)
            DEFAULT_DESCRIPTION.each do |error, default_description|
              error_method = case error
              when :invalid_request
                :bad_request!
              when :insufficient_scope
                :forbidden!
              else
                :unauthorized!
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

          def unauthorized!(error = nil, description = nil, options = {})
            raise 'Define me!'
          end

          def forbidden!(error, description = nil, options = {})
            raise Forbidden.new(error, description, options)
          end
        end

        Request.send :include, ErrorMethods
      end
    end
  end
end
