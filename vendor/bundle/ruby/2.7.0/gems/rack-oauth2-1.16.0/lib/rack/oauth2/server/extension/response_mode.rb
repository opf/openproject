module Rack
  module OAuth2
    module Server
      module Extension
        module ResponseMode
          module AuthorizationRequest
            def self.included(klass)
              klass.send :attr_optional, :response_mode
            end

            def initialize(env)
              super
              @response_mode = params['response_mode']
            end
          end
        end
      end
    end
  end
end