require 'digest/sha1'
require 'openid/store/interface'

module OpenIdAuthentication
  class MemCacheStore < OpenID::Store::Interface
    def initialize(*addresses)
      @connection = ActiveSupport::Cache::MemCacheStore.new(addresses)
    end

    def store_association(server_url, assoc)
      server_key = association_server_key(server_url)
      assoc_key = association_key(server_url, assoc.handle)

      assocs = @connection.read(server_key) || {}
      assocs[assoc.issued] = assoc_key

      @connection.write(server_key, assocs)
      @connection.write(assoc_key, assoc, :expires_in => assoc.lifetime)
    end

    def get_association(server_url, handle = nil)
      if handle
        @connection.read(association_key(server_url, handle))
      else
        server_key = association_server_key(server_url)
        assocs = @connection.read(server_key)
        return if assocs.nil?

        last_key = assocs[assocs.keys.sort.last]
        @connection.read(last_key)
      end
    end

    def remove_association(server_url, handle)
      server_key = association_server_key(server_url)
      assoc_key = association_key(server_url, handle)
      assocs = @connection.read(server_key)

      return false unless assocs && assocs.has_value?(assoc_key)

      assocs = assocs.delete_if { |key, value| value == assoc_key }

      @connection.write(server_key, assocs)
      @connection.delete(assoc_key)

      return true
    end

    def use_nonce(server_url, timestamp, salt)
      return false if @connection.read(nonce_key(server_url, salt))
      return false if (timestamp - Time.now.to_i).abs > OpenID::Nonce.skew
      @connection.write(nonce_key(server_url, salt), timestamp, :expires_in => OpenID::Nonce.skew)
      return true
    end

    private
      def association_key(server_url, handle = nil)
        "openid_association_#{digest(server_url)}_#{digest(handle)}"
      end

      def association_server_key(server_url)
        "openid_association_server_#{digest(server_url)}"
      end

      def nonce_key(server_url, salt)
        "openid_nonce_#{digest(server_url)}_#{digest(salt)}"
      end

      def digest(text)
        Digest::SHA1.hexdigest(text)
      end
  end
end
