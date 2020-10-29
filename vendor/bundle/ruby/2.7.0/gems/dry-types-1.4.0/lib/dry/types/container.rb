# frozen_string_literal: true

require 'dry/container'

module Dry
  module Types
    # Internal container for the built-in types
    #
    # @api private
    class Container
      include Dry::Container::Mixin
    end
  end
end
