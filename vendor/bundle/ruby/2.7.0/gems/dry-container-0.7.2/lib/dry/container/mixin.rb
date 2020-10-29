
require 'concurrent/hash'

module Dry
  class Container
    PREFIX_NAMESPACE = lambda do |namespace, key, config|
      [namespace, key].join(config.namespace_separator)
    end

    EMPTY_HASH = {}.freeze

    # Mixin to expose Inversion of Control (IoC) container behaviour
    #
    # @example
    #
    #   class MyClass
    #     extend Dry::Container::Mixin
    #   end
    #
    #   MyClass.register(:item, 'item')
    #   MyClass.resolve(:item)
    #   => 'item'
    #
    #   class MyObject
    #     include Dry::Container::Mixin
    #   end
    #
    #   container = MyObject.new
    #   container.register(:item, 'item')
    #   container.resolve(:item)
    #   => 'item'
    #
    #
    # @api public
    module Mixin
      # @private
      def self.extended(base)
        hooks_mod = ::Module.new do
          def inherited(subclass)
            subclass.instance_variable_set(:@_container, @_container.dup)
            super
          end
        end

        base.class_eval do
          extend ::Dry::Configurable
          extend hooks_mod

          setting :registry, ::Dry::Container::Registry.new
          setting :resolver, ::Dry::Container::Resolver.new
          setting :namespace_separator, '.'

          @_container = ::Concurrent::Hash.new
        end
      end

      # @private
      module Initializer
        def initialize(*args, &block)
          @_container = ::Concurrent::Hash.new
          super
        end
      end

      # @private
      def self.included(base)
        base.class_eval do
          extend ::Dry::Configurable
          prepend Initializer

          setting :registry, ::Dry::Container::Registry.new
          setting :resolver, ::Dry::Container::Resolver.new
          setting :namespace_separator, '.'

          def config
            self.class.config
          end
        end
      end

      # Register an item with the container to be resolved later
      #
      # @param [Mixed] key
      #   The key to register the container item with (used to resolve)
      # @param [Mixed] contents
      #   The item to register with the container (if no block given)
      # @param [Hash] options
      #   Options to pass to the registry when registering the item
      # @yield
      #   If a block is given, contents will be ignored and the block
      #   will be registered instead
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def register(key, contents = nil, options = EMPTY_HASH, &block)
        if block_given?
          item = block
          options = contents if contents.is_a?(::Hash)
        else
          item = contents
        end

        config.registry.call(_container, key, item, options)

        self
      end

      # Resolve an item from the container
      #
      # @param [Mixed] key
      #   The key for the item you wish to resolve
      # @yield
      #   Fallback block to call when a key is missing. Its result will be returned
      # @yieldparam [Mixed] key Missing key
      #
      # @return [Mixed]
      #
      # @api public
      def resolve(key, &block)
        config.resolver.call(_container, key, &block)
      end

      # Resolve an item from the container
      #
      # @param [Mixed] key
      #   The key for the item you wish to resolve
      #
      # @return [Mixed]
      #
      # @api public
      # @see Dry::Container::Mixin#resolve
      def [](key)
        resolve(key)
      end

      # Merge in the items of the other container
      #
      # @param [Dry::Container] other
      #   The other container to merge in
      # @param [Symbol, nil] namespace
      #   Namespace to prefix other container items with, defaults to nil
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def merge(other, namespace: nil)
        if namespace
          _container.merge!(
            other._container.each_with_object(::Concurrent::Hash.new) do |a, h|
              h[PREFIX_NAMESPACE.call(namespace, a.first, config)] = a.last
            end
          )
        else
          _container.merge!(other._container)
        end

        self
      end

      # Check whether an item is registered under the given key
      #
      # @param [Mixed] key
      #   The key you wish to check for registration with
      #
      # @return [Bool]
      #
      # @api public
      def key?(key)
        config.resolver.key?(_container, key)
      end

      # An array of registered names for the container
      #
      # @return [Array<String>]
      #
      # @api public
      def keys
        config.resolver.keys(_container)
      end

      # Calls block once for each key in container, passing the key as a parameter.
      #
      # If no block is given, an enumerator is returned instead.
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def each_key(&block)
        config.resolver.each_key(_container, &block)
        self
      end

      # Calls block once for each key/value pair in the container, passing the key and the registered item parameters.
      #
      # If no block is given, an enumerator is returned instead.
      #
      # @return [Enumerator]
      #
      # @api public
      #
      # @note In discussions with other developers, it was felt that being able to iterate over not just
      #       the registered keys, but to see what was registered would be very helpful. This is a step
      #       toward doing that.
      def each(&block)
        config.resolver.each(_container, &block)
      end

      # Decorates an item from the container with specified decorator
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def decorate(key, with: nil, &block)
        key = key.to_s
        original = _container.delete(key) do
          raise Error, "Nothing registered with the key #{key.inspect}"
        end

        if with.is_a?(Class)
          decorator = with.method(:new)
        elsif block.nil? && !with.respond_to?(:call)
          raise Error, "Decorator needs to be a Class, block, or respond to the `call` method"
        else
          decorator = with || block
        end

        _container[key] = original.map(decorator)
        self
      end

      # Evaluate block and register items in namespace
      #
      # @param [Mixed] namespace
      #   The namespace to register items in
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def namespace(namespace, &block)
        ::Dry::Container::NamespaceDSL.new(
          self,
          namespace,
          config.namespace_separator,
          &block
        )

        self
      end

      # Import a namespace
      #
      # @param [Dry::Container::Namespace] namespace
      #   The namespace to import
      #
      # @return [Dry::Container::Mixin] self
      #
      # @api public
      def import(namespace)
        namespace(namespace.name, &namespace.block)

        self
      end

      # Freeze the container. Nothing can be registered after freezing
      #
      # @api public
      def freeze
        super
        _container.freeze
        self
      end

      # @private no, really
      def _container
        @_container
      end

      # @api public
      def dup
        copy = super
        copy.instance_variable_set(:@_container, _container.dup)
        copy
      end

      # @api public
      def clone
        copy = super
        unless copy.frozen?
          copy.instance_variable_set(:@_container, _container.dup)
        end
        copy
      end
    end
  end
end
