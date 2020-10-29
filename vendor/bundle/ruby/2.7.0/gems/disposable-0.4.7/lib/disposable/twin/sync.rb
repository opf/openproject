# #sync!
#   1. assign scalars to model (respecting virtual, excluded attributes)
#   2. call sync! on nested
#
# Note: #sync currently implicitly saves AR objects with collections
require 'ostruct'
class Disposable::Twin
  module Sync
    class Options < ::Hash
      def exclude!(names)
        excludes.push(*names)
        self
      end

      def excludes
        self[:exclude] ||= []
      end
    end

    # Creates a fresh copy of the internal representer and adds Representable::Hash.
    # This is used wherever a hash transformation is needed.
    def self.hash_representer(twin_class, &block)
      Disposable::Rescheme.from(twin_class,
        recursive: false,
        definitions_from: lambda { |twin_klass| twin_klass.definitions },
        superclass: Representable::Decorator,
        include: Representable::Hash,
        exclude_options: [:default], # TODO: TEST IN default_test.
        &block
      )
    end

    def sync_models(options={})
      return yield to_nested_hash if block_given?

      sync!(options)
    end
    alias_method :sync, :sync_models

    # Sync all scalar attributes, call sync! on nested and return model.
    def sync!(options) # semi-public.
      # TODO: merge this into Sync::Run or something and use in Struct, too, so we don't
      # need the representer anymore?
      options_for_sync = sync_options(Options[options])

      schema.each(options_for_sync) do |dfn|
        property_value = sync_read(dfn) #

        unless dfn[:nested]
          mapper.send(dfn.setter, property_value) # always sync the property
          next
        end

        # First, call sync! on nested model(s).
        nested_model = PropertyProcessor.new(dfn, self, property_value).() { |twin| twin.sync!({}) }
        next if nested_model.nil?

        # Then, write nested model to parent model, e.g. model.songs = [<Song>]
        mapper.send(dfn.setter, nested_model) # @model.artist = <Artist>
      end

      model
    end

  private
    def self.included(includer)
      includer.extend ToNestedHash::ClassMethods
    end

    def sync_read(definition)
      send(definition.getter)
    end

    # TODO: simplify that using a decent pipeline from Representable.
    module ToNestedHash
      def to_nested_hash(*)
        self.class.nested_hash_representer.new(nested_hash_source).to_hash
      end

      def nested_hash_source
        self
      end

      module ClassMethods
        # Create a hash representer on-the-fly to serialize the form to a hash.
        def nested_hash_representer
          @nested_hash_representer ||= build_nested_hash_representer
        end

        def build_nested_hash_representer
          Sync.hash_representer(self) do |dfn|
            dfn.merge!(
              readable:   true, # the nested hash contains all fields.
              as:         dfn[:private_name], # nested hash keys by model property names.
              render_nil: dfn[:collection] ? nil : true,
            )

            dfn.merge!(
              prepare:   lambda { |options| options[:input] }, # TODO: why do we need that here?
              serialize: lambda { |options| options[:input].to_nested_hash },
            ) if dfn[:nested]
          end
        end # #build_nested_hash_representer
      end
    end
    include ToNestedHash


    module SyncOptions
      def sync_options(options)
        options
      end
    end
    include SyncOptions


    # Excludes :virtual and :writeable: false properties from #sync in this twin.
    module Writeable
      def sync_options(options)
        options = super

        protected_fields = schema.each.find_all { |d| d[:writeable] == false }.collect { |d| d[:name] }
        options.exclude!(protected_fields)
      end
    end
    include Writeable


    # This will skip unchanged properties in #sync. To use this for all nested form do as follows.
    #
    #   class SongForm < Reform::Form
    #     feature Sync::SkipUnchanged
    module SkipUnchanged
      def self.included(base)
        base.send :include, Disposable::Twin::Changed
      end

      def sync_options(options)
        # DISCUSS: we currently don't track if nested forms have changed (only their attributes). that's why i include them all here, which
        # is additional sync work/slightly wrong. solution: allow forms to form.changed? not sure how to do that with collections.
        scalars   = schema.each(scalar: true).collect { |dfn| dfn[:name ]}
        unchanged = scalars - changed.keys

        # exclude unchanged scalars, nested forms and changed scalars still go in here!
        options.exclude!(unchanged)
        super
      end
    end


    # Include this won't use the getter #title in #sync but read directly from @fields.
    module SkipGetter
      def sync_read(dfn)
        @fields[dfn[:name]]
      end

      def nested_hash_source
        OpenStruct.new(@fields)
      end
    end
  end
end
