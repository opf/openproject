require 'dry-configurable'
require 'dry/container/error'
require 'dry/container/namespace'
require 'dry/container/registry'
require 'dry/container/resolver'
require 'dry/container/namespace_dsl'
require 'dry/container/mixin'
require 'dry/container/version'

# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # Inversion of Control (IoC) container
  #
  # @example
  #
  #   container = Dry::Container.new
  #   container.register(:item, 'item')
  #   container.resolve(:item)
  #   => 'item'
  #
  #   container.register(:item1, -> { 'item' })
  #   container.resolve(:item1)
  #   => 'item'
  #
  #   container.register(:item2, -> { 'item' }, call: false)
  #   container.resolve(:item2)
  #   => #<Proc:0x007f33b169e998@(irb):10 (lambda)>
  #
  # @api public
  class Container
    include ::Dry::Container::Mixin
  end
end
