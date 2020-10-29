module Declarative
  Callable = Module.new

  def self.Option(value, options={})
    Option.new.(value, options)
  end

  class Option
    def call(value, options={})
      return lambda_for_proc(value, options)     if value.is_a?(Proc)
      return lambda_for_symbol(value, options)   if value.is_a?(Symbol)
      return lambda_for_callable(value, options) if callable?(value, options)
      lambda_for_static(value, options)
    end

  private

    # All methods below are considered public API and are meant to be overridden.
    def callable?(value, options)
      value.is_a?(options[:callable] || Callable)
    end

    def lambda_for_proc(value, options)
      return ->(context, *args) { context.instance_exec(*args, &value) } if options[:instance_exec]
      value
    end

    def lambda_for_symbol(value, options)
      ->(context, *args){ context.send(value, *args) }
    end

    def lambda_for_callable(value, options)
      value
    end

    def lambda_for_static(value, options)
      ->(*) { value }
    end
  end
end
