require 'openid/util'

module OpenID

  # Stores for Associations and nonces. Used by both the Consumer and
  # the Server. If you have a database abstraction layer or other
  # state storage in your application or framework already, you can
  # implement the store interface.
  module Store
    # Abstract Store
    # Changes in 2.0:
    # * removed store_nonce, get_auth_key, is_dumb
    # * changed use_nonce to support one-way nonces
    # * added cleanup_nonces, cleanup_associations, cleanup
    class Interface < Object

      # Put a Association object into storage.
      # When implementing a store, don't assume that there are any limitations
      # on the character set of the server_url.  In particular, expect to see
      # unescaped non-url-safe characters in the server_url field.
      def store_association(server_url, association)
        raise NotImplementedError
      end

      # Returns a Association object from storage that matches
      # the server_url.  Returns nil if no such association is found or if
      # the one matching association is expired. (Is allowed to GC expired
      # associations when found.)
      def get_association(server_url, handle=nil)
        raise NotImplementedError
      end

      # If there is a matching association, remove it from the store and
      # return true, otherwise return false.
      def remove_association(server_url, handle)
        raise NotImplementedError
      end

      # Return true if the nonce has not been used before, and store it
      # for a while to make sure someone doesn't try to use the same value
      # again.  Return false if the nonce has already been used or if the
      # timestamp is not current.
      # You can use OpenID::Store::Nonce::SKEW for your timestamp window.
      # server_url: URL of the server from which the nonce originated
      # timestamp: time the nonce was created in seconds since unix epoch
      # salt: A random string that makes two nonces issued by a server in
      #       the same second unique
      def use_nonce(server_url, timestamp, salt)
        raise NotImplementedError
      end

      # Remove expired nonces from the store
      # Discards any nonce that is old enough that it wouldn't pass use_nonce
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup_nonces
        raise NotImplementedError
      end

      # Remove expired associations from the store
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup_associations
        raise NotImplementedError
      end

      # Remove expired nonces and associations from the store
      # Not called during normal library operation, this method is for store
      # admins to keep their storage from filling up with expired data
      def cleanup
        return cleanup_nonces, cleanup_associations
      end
    end
  end
end
