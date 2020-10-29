# frozen_string_literal: true

module Airbrake
  module Rack
    # Instrumentable holds methods that simplify instrumenting Rack apps.
    # @example
    #   class UsersController
    #     extend Airbrake::Rack::Instrumentable
    #
    #     def index
    #       # ...
    #     end
    #     airbrake_capture_timing :index
    #   end
    #
    # @api public
    # @since v9.2.0
    module Instrumentable
      def airbrake_capture_timing(method_name, label: method_name.to_s)
        instrumentable = ::Airbrake::Rack::Instrumentable
        if instrumentable.should_prepend?(self, method_name)
          instrumentable.prepend_capture_timing(self, method_name, label)
        else
          instrumentable.chain_capture_timing(self, method_name, label)
        end
        method_name
      end

      # @api private
      def __airbrake_capture_timing_module__
        # Module used to store prepended wrapper methods, saved as an instance
        # variable so each target class/module gets its own module. This just
        # a convenience to avoid prepending a lot of anonymous modules.
        @__airbrake_capture_timing_module__ ||= ::Module.new
      end
      private :__airbrake_capture_timing_module__

      # Using api private self methods so they don't get defined in the target
      # class or module, but can still be called by the above method.

      # @api private
      def self.should_prepend?(klass, method_name)
        # Don't chain already-prepended or operator methods.
        klass.module_exec do
          self_class_idx = ancestors.index(self)
          method_owner_idx = ancestors.index(instance_method(method_name).owner)
          method_owner_idx < self_class_idx || !(/\A\W/ =~ method_name).nil?
        end
      end

      # @api private
      def self.prepend_capture_timing(klass, method_name, label)
        args = method_signature
        visibility = method_visibility(klass, method_name)

        # Generate the wrapper method.
        klass.module_exec do
          mod = __airbrake_capture_timing_module__
          mod.module_exec do
            module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_name}(#{args})
                Airbrake::Rack.capture_timing(#{label.to_s.inspect}) do
                  super
                end
              end
              #{visibility} :#{method_name}
            RUBY
          end
          prepend mod
        end
      end

      # @api private
      def self.chain_capture_timing(klass, method_name, label)
        args = method_signature
        visibility = method_visibility(klass, method_name)

        # Generate the wrapper method.
        aliased = method_name.to_s.sub(/([?!=])$/, '')
        punctuation = Regexp.last_match(1)
        wrapped_method_name = "#{aliased}_without_airbrake#{punctuation}"
        needs_removal = method_needs_removal(klass, method_name)
        klass.module_exec do
          alias_method wrapped_method_name, method_name
          remove_method method_name if needs_removal
          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(#{args})
              Airbrake::Rack.capture_timing(#{label.to_s.inspect}) do
                __send__("#{aliased}_without_airbrake#{punctuation}", #{args})
              end
            end
            #{visibility} :#{method_name}
          RUBY
        end
      end

      # @api private
      def self.method_visibility(klass, method_name)
        klass.module_exec do
          if protected_method_defined?(method_name)
            "protected"
          elsif private_method_defined?(method_name)
            "private"
          else
            "public"
          end
        end
      end

      # @api private
      # A method instead of a constant so it isn't accessible in the target.
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7")
        def self.method_signature
          "*args, **kw_args, &block"
        end
      else
        def self.method_signature
          "*args, &block"
        end
      end

      # @api private
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6")
        def self.method_needs_removal(klass, method_name)
          klass.method_defined?(method_name, false) ||
            klass.private_method_defined?(method_name, false)
        end
      else
        def self.method_needs_removal(klass, method_name)
          klass.instance_methods(false).include?(method_name) ||
            klass.private_instance_methods(false).include?(method_name)
        end
      end
    end
  end
end
