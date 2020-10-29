# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < RedisProxy
        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def read(key)
          rescuing { get(key, raw: true) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            rescuing { setex(key, expires_in, value, raw: true) }
          else
            rescuing { set(key, value, raw: true) }
          end
        end
      end
    end
  end
end
