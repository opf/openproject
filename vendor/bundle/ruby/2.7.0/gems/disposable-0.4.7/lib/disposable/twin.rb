require "uber/inheritable_attr"
require "declarative/schema"
require "representable/decorator"

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.

module Disposable
  class Twin
    class InvalidPropertyNameError < StandardError; end
    INVALID_PROPERTY_NAMES = %i[class].freeze

    extend Declarative::Schema
    def self.definition_class
      Definition
    end

    def self.inherited(subclass)
      # no super here!
      heritage.(subclass) do |cfg|
        cfg[:args].last.merge!(_inherited: true) if cfg[:method] == :property
      end
    end

    def schema
      Definition::Each.new(self.class.definitions) # TODO: change this interface.
    end

    class << self
      def default_nested_class
        Twin
      end

      # TODO: move to Declarative, as in Representable and Reform.
      def property(name, options={}, &block)
        if INVALID_PROPERTY_NAMES.include?(name)
          raise InvalidPropertyNameError.new("#{name} is used internally and cannot be used as property name")
        end

        options[:private_name] ||= options.delete(:from) || name
        is_inherited = options.delete(:_inherited)

        if options.delete(:virtual)
          options[:writeable] = options[:readable] = false
        end

        options[:nested] = options.delete(:twin) if options[:twin]

        super(name, options, &block).tap do |definition| # super is Declarative::Schema::property.
          create_accessors(name, definition) unless is_inherited
        end
      end

      def collection(name, options={}, &block)
        property(name, options.merge(collection: true), &block)
      end

      require "disposable/twin/property/unnest"
      include Property::Unnest

      # TODO: remove.
      def from_collection(collection)
        collection.collect { |model| new(model) }
      end

    private

      def create_accessors(name, definition)
        mod = Module.new do
          define_method(name)       { @fields[name.to_s] }
          # define_method(name)       { read_property(name) }
          define_method("#{name}=") { |value| write_property(name, value, definition) }
        end
        include mod
      end
    end

    require "disposable/twin/setup"
    include Setup


    module Accessors
    private
      # assumption: collections are always initialized from Setup since we assume an empty [] for "nil"/uninitialized collections.
      def write_property(name, value, dfn)
        value = build_for(dfn, value) if dfn[:nested] and value

        field_write(name, value)
      end

      # Write the property's value without using the public writer.
      def field_write(name, value)
        @fields[name.to_s] = value
      end

      # Read the property's value without using the public reader.
      def field_read(name)
        @fields[name.to_s]
      end

      # Build a twin or a Twin::Collection for the value (which is a model or array of).
      def build_for(dfn, *args)
        dfn[:collection] ? build_collection(dfn, *args) : build_twin(dfn, *args)
      end

      def build_twin(dfn, *args)
        dfn[:nested].new(*args) # Twin.new(model, options={})
      end

      def build_collection(dfn, *args)
        Collection.for_models(Twinner.new(self, dfn), *args)
      end
    end
    include Accessors

    # TODO: make this a function so it's faster at run-time.
    class Twinner
      def initialize(twin, dfn)
        @twin = twin
        @dfn  = dfn
      end

      def call(*args)
        @twin.send(:build_twin, @dfn, *args)
      end
    end

  private
    module ModelReaders
      attr_reader :model # #model is a private concept.
      attr_reader :mapper
    end
    include ModelReaders
  end
end

require "disposable/twin/definitions"
require "disposable/twin/collection"
require "disposable/twin/sync"
require "disposable/twin/save"
require "disposable/twin/builder"
require "disposable/twin/changed"
require "disposable/twin/property_processor"
require "disposable/twin/persisted"
require "disposable/twin/default"
