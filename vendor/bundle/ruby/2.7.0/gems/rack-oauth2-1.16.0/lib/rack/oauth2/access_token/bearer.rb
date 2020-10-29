module Rack
  module OAuth2
    class AccessToken
      class Bearer < AccessToken
        def authenticate(request)
          request.header["Authorization"] = "Bearer #{access_token}"
        end

        def to_mtls(attributes = {})
          (required_attributes + optional_attributes).each do |key|
            attributes[key] = self.send(key)
          end
          MTLS.new attributes
        end
      end
    end
  end
end
