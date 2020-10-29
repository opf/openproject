module OpenIDConnect
  class ResponseObject
    class UserInfo
      class Address < ConnectObject
        attr_optional :formatted, :street_address, :locality, :region, :postal_code, :country
        validate :require_at_least_one_attributes
      end
    end
  end
end