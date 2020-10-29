module WillPaginate::Deprecation
  class << self
    def warn(message, stack = caller)
      offending_line = origin_of_call(stack)
      full_message = "DEPRECATION WARNING: #{message} (called from #{offending_line})"
      logger = rails_logger || Kernel
      logger.warn full_message
    end

    private

    def rails_logger
      defined?(Rails.logger) && Rails.logger
    end

    def origin_of_call(stack)
      lib_root = File.expand_path('../../..', __FILE__)
      stack.find { |line| line.index(lib_root) != 0 } || stack.first
    end
  end

  class Hash < ::Hash
    def initialize(values = {})
      super()
      update values
      @deprecated = {}
    end

    def []=(key, value)
      check_deprecated(key, value)
      super
    end

    def deprecate_key(*keys, &block)
      message = block_given? ? block : keys.pop
      Array(keys).each { |key| @deprecated[key] = message }
    end

    def merge(another)
      to_hash.update(another)
    end

    def to_hash
      ::Hash.new.update(self)
    end

    private

    def check_deprecated(key, value)
      if msg = @deprecated[key] and (!msg.respond_to?(:call) or (msg = msg.call(key, value)))
        WillPaginate::Deprecation.warn(msg)
      end
    end
  end
end
