require 'hmac/hmac'
require 'digest/sha1'

module HMAC
  class SHA1 < Base
    def initialize(key = nil)
      super(Digest::SHA1, 64, 20, key)
    end
    public_class_method :new, :digest, :hexdigest
  end
end
