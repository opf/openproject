require 'hmac/hmac'
require 'digest/sha2'

module HMAC
  class SHA256 < Base
    def initialize(key = nil)
      super(Digest::SHA256, 64, 32, key)
    end
    public_class_method :new, :digest, :hexdigest
  end

  class SHA384 < Base
    def initialize(key = nil)
      super(Digest::SHA384, 128, 48, key)
    end
    public_class_method :new, :digest, :hexdigest
  end

  class SHA512 < Base
    def initialize(key = nil)
      super(Digest::SHA512, 128, 64, key)
    end
    public_class_method :new, :digest, :hexdigest
  end
end
