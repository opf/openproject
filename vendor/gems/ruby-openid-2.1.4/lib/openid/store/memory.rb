require 'openid/store/interface'
module OpenID
  module Store
    # An in-memory implementation of Store.  This class is mainly used
    # for testing, though it may be useful for long-running single
    # process apps.  Note that this store is NOT thread-safe.
    #
    # You should probably be looking at OpenID::Store::Filesystem
    class Memory < Interface

      def initialize
        @associations = {}
        @associations.default = {}
        @nonces = {}
      end

      def store_association(server_url, assoc)
        assocs = @associations[server_url]
        @associations[server_url] = assocs.merge({assoc.handle => deepcopy(assoc)})
      end

      def get_association(server_url, handle=nil)
        assocs = @associations[server_url]
        assoc = nil
        if handle
          assoc = assocs[handle]
        else
          assoc = assocs.values.sort{|a,b| a.issued <=> b.issued}[-1]
        end

        return assoc
      end

      def remove_association(server_url, handle)
        assocs = @associations[server_url]
        if assocs.delete(handle)
          return true
        else
          return false
        end
      end

      def use_nonce(server_url, timestamp, salt)
        return false if (timestamp - Time.now.to_i).abs > Nonce.skew
        nonce = [server_url, timestamp, salt].join('')
        return false if @nonces[nonce]
        @nonces[nonce] = timestamp
        return true
      end

      def cleanup_associations
        count = 0
        @associations.each{|server_url, assocs|
          assocs.each{|handle, assoc|
            if assoc.expires_in == 0
              assocs.delete(handle)
              count += 1
            end
          }
        }
        return count
      end

      def cleanup_nonces
        count = 0
        now = Time.now.to_i
        @nonces.each{|nonce, timestamp|
          if (timestamp - now).abs > Nonce.skew
            @nonces.delete(nonce)
            count += 1
          end
        }
        return count
      end

      protected

      def deepcopy(o)
        Marshal.load(Marshal.dump(o))
      end

    end
  end
end
