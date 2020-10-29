# frozen_String_literal: true

require 'singleton'
require 'forwardable'

module Grape
  module Util
    class Cache
      include Singleton

      attr_reader :cache

      class << self
        extend Forwardable
        def_delegators :cache, :[]
        def_delegators :instance, :cache
      end
    end
  end
end
