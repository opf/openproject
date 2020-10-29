module Airbrake
  # HashKeyable allows instances of the class to be used as a Hash key in a
  # consistent manner.
  #
  # The class that includes it must implement *to_h*, which defines properties
  # that all of the instances must share in order to produce the same {#hash}.
  #
  # @example
  #   class C
  #     include Airbrake::HashKeyable
  #
  #     def initialize(key)
  #       @key = key
  #     end
  #
  #     def to_h
  #       { 'key' => @key }
  #     end
  #   end
  #
  #   h = {}
  #   h[C.new('key1')] = 1
  #   h[C.new('key1')] #=> 1
  #   h[C.new('key2')] #=> nil
  module HashKeyable
    # @param [Object] other
    # @return [Boolean]
    def eql?(other)
      other.is_a?(self.class) && other.hash == hash
    end

    # @return [Integer]
    def hash
      to_h.hash
    end
  end
end
