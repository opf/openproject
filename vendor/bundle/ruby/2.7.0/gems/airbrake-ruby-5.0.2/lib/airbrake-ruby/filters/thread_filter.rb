module Airbrake
  module Filters
    # Attaches thread & fiber local variables along with general thread
    # information.
    # @api private
    class ThreadFilter
      # @return [Integer]
      attr_reader :weight

      # @return [Array<Class>] the list of classes that can be safely converted
      #   to JSON
      SAFE_CLASSES = [
        NilClass,
        TrueClass,
        FalseClass,
        String,
        Symbol,
        Regexp,
        Numeric,
      ].freeze

      # Variables starting with this prefix are not attached to a notice.
      # @see https://github.com/airbrake/airbrake-ruby/issues/229
      # @return [String]
      IGNORE_PREFIX = '_'.freeze

      def initialize
        @weight = 110
      end

      # @macro call_filter
      def call(notice)
        th = Thread.current
        thread_info = {}

        if (vars = thread_variables(th)).any?
          thread_info[:thread_variables] = vars
        end

        if (vars = fiber_variables(th)).any?
          thread_info[:fiber_variables] = vars
        end

        # Present in Ruby 2.3+.
        if th.respond_to?(:name) && (name = th.name)
          thread_info[:name] = name
        end

        add_thread_info(th, thread_info)

        notice[:params][:thread] = thread_info
      end

      private

      def thread_variables(th)
        th.thread_variables.map.with_object({}) do |var, h|
          next if var.to_s.start_with?(IGNORE_PREFIX)

          h[var] = sanitize_value(th.thread_variable_get(var))
        end
      end

      def fiber_variables(th)
        th.keys.map.with_object({}) do |key, h|
          next if key.to_s.start_with?(IGNORE_PREFIX)

          h[key] = sanitize_value(th[key])
        end
      end

      def add_thread_info(th, thread_info)
        thread_info[:self] = th.inspect
        thread_info[:group] = th.group.list.map(&:inspect)
        thread_info[:priority] = th.priority

        thread_info[:safe_level] = th.safe_level if Airbrake::HAS_SAFE_LEVEL
      end

      def sanitize_value(value)
        return value if SAFE_CLASSES.any? { |klass| value.is_a?(klass) }

        case value
        when Array
          value = value.map { |elem| sanitize_value(elem) }
        when Hash
          Hash[value.map { |k, v| [k, sanitize_value(v)] }]
        else
          value.to_s
        end
      end
    end
  end
end
