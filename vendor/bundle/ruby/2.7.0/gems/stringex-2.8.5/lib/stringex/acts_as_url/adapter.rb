require "stringex/acts_as_url/adapter/base"
require "stringex/acts_as_url/adapter/active_record"
require "stringex/acts_as_url/adapter/data_mapper"
require "stringex/acts_as_url/adapter/mongoid"

module Stringex
  module ActsAsUrl
    module Adapter
      def self.add_loaded_adapter(adapter)
        @loaded_adapters << adapter
      end

      def self.load_available
        @loaded_adapters = []
        constants.each do |name|
          adapter = const_get(name)
          adapter.load if adapter.loadable?
        end
      end

      def self.first_available
        @loaded_adapters[0]
      end
    end
  end
end