# frozen_string_literal: true

require 'logger'

module Dry
  module Core
    # An extension for issueing warnings on using deprecated methods.
    #
    # @example
    #
    #   class Foo
    #     def self.old_class_api; end
    #     def self.new_class_api; end
    #
    #     deprecate_class_method :old_class_api, :new_class_api
    #
    #     def old_api; end
    #     def new_api; end
    #
    #     deprecate_method :old_api, :new_api, "old_api is no-no"
    #   end
    #
    # @example You also can use this module for your custom messages
    #
    #   Dry::Core::Deprecations.announce("Foo", "use bar instead")
    #   Dry::Core::Deprecations.warn("Baz is going to be removed soon")
    #
    # @api public
    module Deprecations
      STACK = -> { caller.find { |l| l !~ %r{(lib/dry/core)|(gems)} } }

      class << self
        # Prints a warning
        #
        # @param [String] msg Warning string
        def warn(msg, tag: nil)
          tagged = "[#{tag || 'deprecated'}] #{msg.gsub(/^\s+/, '')}"
          logger.warn(tagged)
        end

        # Wraps arguments with a standard message format and prints a warning
        #
        # @param [Object] name what is deprecated
        # @param [String] msg additional message usually containing upgrade instructions
        def announce(name, msg, tag: nil)
          warn(deprecation_message(name, msg), tag: tag)
        end

        # @api private
        def deprecation_message(name, msg)
          <<-MSG
            #{ name } is deprecated and will be removed in the next major version
            #{ msg }
          MSG
        end

        # @api private
        def deprecated_name_message(old, new = nil, msg = nil)
          if new
            deprecation_message(old, <<-MSG)
              Please use #{new} instead.
              #{msg}
            MSG
          else
            deprecation_message(old, msg)
          end
        end

        # Returns the logger used for printing warnings.
        # You can provide your own with .set_logger!
        #
        # @param [IO] output output stream
        #
        # @return [Logger]
        def logger(output = $stderr)
          if defined?(@logger)
            @logger
          else
            set_logger!(output)
          end
        end

        # Sets a custom logger. This is a global setting.
        #
        # @overload set_logger!(output)
        #   @param [IO] output Stream for messages
        #
        # @overload set_logger!
        #   Stream messages to stdout
        #
        # @overload set_logger!(logger)
        #   @param [#warn] logger
        #
        # @api public
        def set_logger!(output = $stderr)
          if output.respond_to?(:warn)
            @logger = output
          else
            @logger = Logger.new(output).tap do |logger|
              logger.formatter = proc { |_, _, _, msg| "#{ msg }\n" }
            end
          end
        end

        def [](tag)
          Tagged.new(tag)
        end
      end

      # @api private
      class Tagged < Module
        def initialize(tag)
          @tag = tag
        end

        def extended(base)
          base.extend Interface
          base.deprecation_tag @tag
        end
      end

      module Interface
        # Sets/gets deprecation tag
        #
        # @option [String,Symbol] tag tag
        def deprecation_tag(tag = nil)
          if defined?(@deprecation_tag)
            @deprecation_tag
          else
            @deprecation_tag = tag
          end
        end

        # Issue a tagged warning message
        #
        # @param [String] msg warning message
        def warn(msg)
          Deprecations.warn(msg, tag: deprecation_tag)
        end

        # Mark instance method as deprecated
        #
        # @param [Symbol] old_name deprecated method
        # @param [Symbol] new_name replacement (not required)
        # @option [String] message optional deprecation message
        def deprecate(old_name, new_name = nil, message: nil)
          full_msg = Deprecations.deprecated_name_message(
            "#{self.name}##{old_name}",
            new_name ? "#{self.name}##{new_name}" : nil,
            message
          )
          mod = self

          if new_name
            undef_method old_name if method_defined?(old_name)

            define_method(old_name) do |*args, &block|
              mod.warn("#{ full_msg }\n#{ STACK.() }")
              __send__(new_name, *args, &block)
            end
          else
            aliased_name = :"#{old_name}_without_deprecation"
            alias_method aliased_name, old_name
            private aliased_name
            undef_method old_name

            define_method(old_name) do |*args, &block|
              mod.warn("#{ full_msg }\n#{ STACK.() }")
              __send__(aliased_name, *args, &block)
            end
          end
        end

        # Mark class-level method as deprecated
        #
        # @param [Symbol] old_name deprecated method
        # @param [Symbol] new_name replacement (not required)
        # @option [String] message optional deprecation message
        def deprecate_class_method(old_name, new_name = nil, message: nil)
          full_msg = Deprecations.deprecated_name_message(
            "#{self.name}.#{old_name}",
            new_name ? "#{self.name}.#{new_name}" : nil,
            message
          )

          meth = new_name ? method(new_name) : method(old_name)

          singleton_class.instance_exec do
            undef_method old_name if method_defined?(old_name)

            define_method(old_name) do |*args, &block|
              warn("#{ full_msg }\n#{ STACK.() }")
              meth.call(*args, &block)
            end
          end
        end

        # Mark a constant as deprecated
        # @param [Symbol] constant_name constant name to be deprecated
        # @option [String] message optional deprecation message
        def deprecate_constant(constant_name, message: nil)
          value = const_get(constant_name)
          remove_const(constant_name)

          full_msg = Deprecations.deprecated_name_message(
            "#{self.name}::#{constant_name}",
            message
          )

          mod = Module.new do
            define_method(:const_missing) do |missing|
              if missing == constant_name
                warn("#{ full_msg }\n#{ STACK.() }")
                value
              else
                super(missing)
              end
            end
          end

          extend(mod)
        end
      end
    end
  end
end
