module Rack
  module Accept
    VERSION = [0, 4, 5]

    # Returns the current version of Rack::Accept as a string.
    def self.version
      VERSION.join('.')
    end
  end
end
