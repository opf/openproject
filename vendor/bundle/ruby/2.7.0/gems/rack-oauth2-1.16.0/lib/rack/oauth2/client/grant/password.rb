module Rack
  module OAuth2
    class Client
      class Grant
        class Password < Grant
          attr_required :username, :password
        end
      end
    end
  end
end