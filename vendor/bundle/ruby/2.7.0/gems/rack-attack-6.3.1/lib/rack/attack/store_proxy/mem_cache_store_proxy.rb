# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class MemCacheStoreProxy < SimpleDelegator
        def self.handle?(store)
          defined?(::Dalli) &&
            defined?(::ActiveSupport::Cache::MemCacheStore) &&
            store.is_a?(::ActiveSupport::Cache::MemCacheStore)
        end

        def write(name, value, options = {})
          super(name, value, options.merge!(raw: true))
        end
      end
    end
  end
end
