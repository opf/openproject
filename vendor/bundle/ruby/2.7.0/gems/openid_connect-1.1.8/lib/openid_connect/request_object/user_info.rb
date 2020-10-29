module OpenIDConnect
  class RequestObject
    class UserInfo < ConnectObject
      include Claimable
    end
  end
end