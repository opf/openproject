module OpenIDConnect
  module Discovery
    module Provider
      module Issuer
        REL_VALUE = 'http://openid.net/specs/connect/1.0/issuer'

        def issuer
          self.link_for(REL_VALUE)[:href]
        end
      end

      def self.discover!(identifier)
        resource = case identifier
        when /^acct:/, /https?:\/\//
          identifier
        when /@/
          "acct:#{identifier}"
        else
          "https://#{identifier}"
        end
        response = WebFinger.discover!(
          resource,
          rel: Issuer::REL_VALUE
        )
        response.extend Issuer
        response
      rescue WebFinger::Exception => e
        raise DiscoveryFailed.new(e.message)
      end
    end
  end
end

require 'openid_connect/discovery/provider/config'