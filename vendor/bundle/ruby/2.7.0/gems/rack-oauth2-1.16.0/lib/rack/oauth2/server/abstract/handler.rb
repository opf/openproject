module Rack
  module OAuth2
    module Server
      module Abstract
        class Handler
          attr_accessor :authenticator, :request, :response

          def initialize(&authenticator)
            @authenticator = authenticator
          end

          def call(env)
            # NOTE:
            #  Rack middleware is initialized only on the first request of the process.
            #  So any instance variables are acts like class variables, and modifying them in call() isn't thread-safe.
            #  ref.) http://stackoverflow.com/questions/23028226/rack-middleware-and-thread-safety
            dup._call(env)
          end

          def _call(env)
            @authenticator.call(@request, @response) if @authenticator
            @response
          end
        end
      end
    end
  end
end