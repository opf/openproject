module Delayed
  class DelayProxy < Delayed::Compatibility.proxy_object_class
    def initialize(payload_class, target, options)
      @payload_class = payload_class
      @target = target
      @options = options
    end

    # rubocop:disable MethodMissing
    def method_missing(method, *args)
      Job.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args)}.merge(@options))
    end
    # rubocop:enable MethodMissing
  end

  module MessageSending
    def delay(options = {})
      DelayProxy.new(PerformableMethod, self, options)
    end
    alias_method :__delay__, :delay

    def send_later(method, *args)
      warn '[DEPRECATION] `object.send_later(:method)` is deprecated. Use `object.delay.method'
      __delay__.__send__(method, *args)
    end

    def send_at(time, method, *args)
      warn '[DEPRECATION] `object.send_at(time, :method)` is deprecated. Use `object.delay(:run_at => time).method'
      __delay__(:run_at => time).__send__(method, *args)
    end
  end

  module MessageSendingClassMethods
    def handle_asynchronously(method, opts = {}) # rubocop:disable PerceivedComplexity
      aliased_method = method.to_s.sub(/([?!=])$/, '')
      punctuation = $1 # rubocop:disable PerlBackrefs
      with_method = "#{aliased_method}_with_delay#{punctuation}"
      without_method = "#{aliased_method}_without_delay#{punctuation}"
      define_method(with_method) do |*args|
        curr_opts = opts.clone
        curr_opts.each_key do |key|
          next unless (val = curr_opts[key]).is_a?(Proc)
          curr_opts[key] = if val.arity == 1
            val.call(self)
          else
            val.call
          end
        end
        delay(curr_opts).__send__(without_method, *args)
      end

      alias_method without_method, method
      alias_method method, with_method

      if public_method_defined?(without_method)
        public method
      elsif protected_method_defined?(without_method)
        protected method
      elsif private_method_defined?(without_method)
        private method
      end
    end
  end
end
