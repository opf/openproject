# frozen_string_literal: true

require 'dry/configurable/constants'
require 'dry/configurable/setting'

module Dry
  module Configurable
    class DSL
      # @api private
      class Args
        # @api private
        attr_reader :args

        # @api private
        attr_reader :size

        # @api private
        attr_reader :opts

        # @api private
        def initialize(args)
          @args = args
          @size = args.size
          @opts = Setting::OPTIONS
        end

        # @api private
        def ensure_valid_options
          return unless options

          keys = options.keys - opts
          raise ArgumentError, "Invalid options: #{keys.inspect}" unless keys.empty?
        end

        # @api private
        def to_ary
          [default, options || EMPTY_HASH]
        end

        # @api private
        def default
          if size.equal?(1) && options.nil?
            args[0]
          elsif size > 1 && options
            args[0]
          else
            Undefined
          end
        end

        # @api private
        def options
          args.detect { |arg| arg.is_a?(Hash) && (opts & arg.keys).any? }
        end
      end
    end
  end
end
