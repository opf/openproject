# frozen_string_literal: true

require 'dry/types/constructor'

module Dry
  module Types
    # Hash type exposes additional APIs for working with schema hashes
    #
    # @api public
    class Hash < Nominal
      class Constructor < ::Dry::Types::Constructor
        # @api private
        def constructor_type
          ::Dry::Types::Hash::Constructor
        end

        # @return [Lax]
        #
        # @api public
        def lax
          type.lax.constructor(fn, meta: meta)
        end

        # @see Dry::Types::Array#of
        #
        # @api public
        def schema(*args)
          type.schema(*args).constructor(fn, meta: meta)
        end
      end
    end
  end
end
