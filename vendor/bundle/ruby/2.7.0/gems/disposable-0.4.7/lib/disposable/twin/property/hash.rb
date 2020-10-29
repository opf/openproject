require "disposable/twin/struct"

class Disposable::Twin
  module Property
    # trailblazer.to/gems/disposable/api.html#hash
    module Hash
      def self.included(includer)
        # hash: true top-level properties need :default support.
        includer.feature Default

        # Recursively include Struct in :hash and nested properties.
        # defaults is applied to all ::property calls.
        includer.defaults do |name, options|
          if options[:field] == :hash
            hash_options
          else
            {}
          end
        end
      end

    private
      # Note that :_features `include`s modules in this order, first to last.
      def self.hash_options
        { _features: [NestedDefaults, Property::Struct, Hash::Sync], default: ->(*) { ::Hash.new } }
      end

      # NestedDefaults for properties nested in the top :hash column.
      module NestedDefaults
        def self.included(includer)
          includer.defaults do |name, options|
            if options[:_nested_builder] # DISCUSS: any other way to figure out we're nested?
              Hash.hash_options
            else
              { }
            end
          end
        end
      end

      module Sync
        def sync!(options={})
          @model.merge(super)
        end
      end
    end
  end
end
