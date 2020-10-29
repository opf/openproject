# frozen_string_literal: true

module Rack
  class Attack
    module StoreProxy
      PROXIES = [
        DalliProxy,
        MemCacheStoreProxy,
        RedisStoreProxy,
        RedisProxy,
        RedisCacheStoreProxy,
        ActiveSupportRedisStoreProxy
      ].freeze

      def self.build(store)
        klass = PROXIES.find { |proxy| proxy.handle?(store) }
        klass ? klass.new(store) : store
      end
    end
  end
end
