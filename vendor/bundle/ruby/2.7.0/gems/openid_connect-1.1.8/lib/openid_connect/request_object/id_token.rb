module OpenIDConnect
  class RequestObject
    class IdToken < ConnectObject
      include Claimable
      attr_optional :max_age
    end
  end
end