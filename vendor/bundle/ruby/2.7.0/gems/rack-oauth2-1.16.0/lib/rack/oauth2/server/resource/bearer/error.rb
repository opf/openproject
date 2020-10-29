module Rack
  module OAuth2
    module Server
      class Resource
        class Bearer
          class Unauthorized < Resource::Unauthorized
            def scheme
              :Bearer
            end
          end

          module ErrorMethods
            include Resource::ErrorMethods
            def unauthorized!(error = nil, description = nil, options = {})
              raise Unauthorized.new(error, description, options)
            end
          end

          Request.send :include, ErrorMethods
        end
      end
    end
  end
end