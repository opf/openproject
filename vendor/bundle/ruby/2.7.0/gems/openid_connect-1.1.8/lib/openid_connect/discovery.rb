module OpenIDConnect
  module Discovery
    class InvalidIdentifier < Exception; end
    class DiscoveryFailed < Exception; end
  end
end

require 'openid_connect/discovery/provider'