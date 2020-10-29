module Rack
  module OAuth2
    class Client
      class Error < StandardError
        attr_accessor :status, :response
        def initialize(status, response)
          @status = status
          @response = response
          message = [response[:error], response[:error_description]].compact.join(' :: ')
          super message
        end
      end
    end
  end
end
