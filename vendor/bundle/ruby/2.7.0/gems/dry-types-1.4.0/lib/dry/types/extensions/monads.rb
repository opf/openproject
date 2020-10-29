# frozen_string_literal: true

require 'dry/monads/result'

module Dry
  module Types
    # Monad extension for Result
    #
    # @api public
    class Result
      include Dry::Monads::Result::Mixin

      # Turn result into a monad
      #
      # This makes result objects work with dry-monads (or anything with a compatible interface)
      #
      # @return [Dry::Monads::Success,Dry::Monads::Failure]
      #
      # @api public
      def to_monad
        if success?
          Success(input)
        else
          Failure([error, input])
        end
      end
    end
  end
end
