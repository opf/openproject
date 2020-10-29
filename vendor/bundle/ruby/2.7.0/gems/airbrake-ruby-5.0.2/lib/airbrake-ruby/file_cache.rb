module Airbrake
  # Extremely simple global cache.
  #
  # @api private
  # @since v2.4.1
  module FileCache
    # @return [Integer]
    MAX_SIZE = 50

    # @return [Mutex]
    MUTEX = Mutex.new

    # Associates the value given by +value+ with the key given by +key+. Deletes
    # entries that exceed +MAX_SIZE+.
    #
    # @param [Object] key
    # @param [Object] value
    # @return [Object] the corresponding value
    def self.[]=(key, value)
      MUTEX.synchronize do
        data[key] = value
        data.delete(data.keys.first) if data.size > MAX_SIZE
      end
    end

    # Retrieve an object from the cache.
    #
    # @param [Object] key
    # @return [Object] the corresponding value
    def self.[](key)
      MUTEX.synchronize do
        data[key]
      end
    end

    # Checks whether the cache is empty. Needed only for the test suite.
    #
    # @return [Boolean]
    def self.empty?
      data.empty?
    end

    # @since 4.7.0
    # @return [void]
    def self.reset
      @data = {}
    end

    def self.data
      @data ||= {}
    end
    private_class_method :data
  end
end
