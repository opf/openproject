# Callback is designed to work with twins under the hood since twins track events
# like "adding" or "deleted". However, it could run with other model layers, too.
# For example, when you manage to make ActiveRecord track those events, you won't need a
# twin layer underneath.
module Disposable::Callback
  # Order matters.
  #   on_change :change!
  #   collection :songs do
  #     on_add :notify_album!
  #     on_add :reset_song!
  #
  # you can call collection :songs again, with :inherit. TODO: verify.

  class Group
    extend Declarative::Schema

    def self.default_nested_class
      Group
    end

    def self.clone
      Class.new(self)
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(collection: true), &block)
    end

    def self.property(name, options={}, &block)
      # NOTE: while the API will stay the same, it's very likely i'm gonna use Declarative::Config here instead
      # of maintaining two stacks of callbacks.
      # it should have a Definition per callback where the representer_module will be a nested Group or a Callback.
      inherit = options[:inherit] # FIXME: this is deleted in ::property.

      super(name, options, &block).tap do |dfn|
        return if inherit
        hooks << ["property", dfn[:name]]
      end
    end

    def self.remove!(event, callback)
      hooks.delete hooks.find { |cfg| cfg[0] == event && cfg[1] == callback }
    end


    def initialize(twin)
      @twin = twin
      @invocations = []
    end

    attr_reader :invocations

    def self.hooks
      @hooks ||= []
    end


    class << self
      %w(on_add on_delete on_destroy on_update on_create on_change).each do |event|
        define_method event do |method, options={}|
          heritage.record(event, method, options)

          hooks << [event.to_sym, method, options] # DISCUSS: can't we simply instantiate Callables here?
        end
      end
    end


    def call(options={})
      self.class.hooks.each do |event, method, property_options|
        if event == "property" # FIXME: make nicer.
          definition = self.class.definitions.get(method)
          twin = @twin.send(definition[:name]) # album.songs

          # recursively call nested group.
          @invocations += definition[:nested].new(twin).(options).invocations # Group.new(twin).()
          next
        end

        invocations << callback!(event, options, method, property_options)
      end

      self
    end

  private
    # Runs one callback, e.g. for `on_change :smile!`.
    def callback!(event, options, method, property_options) # TODO: remove args.
      context = options[:context] || self # TODO: test me.

      # TODO: Use Option::Value here. this could be created straight in the DSL with the twin being passed in.
      if context.methods.include?(method) && context.method(method).arity == 1 # TODO: remove in 0.3.
        warn "[Disposable] Callback handlers now receive two options: #{method}(twin, options)."
        return Dispatch.new(@twin).(event, method, property_options) { |twin| context.send(method, twin) }
      end

      Dispatch.new(@twin).(event, method, property_options) { |twin| context.send(method, twin, options) }
    end
  end


  # Invokes callback for one event, e.g. on_add(:relax!).
  # Implements the binding between the Callback API (on_change) and the underlying layer (twin/AR/etc.).
  class Dispatch
    def initialize(twins)
      @twins = Array(twins) # TODO: find that out with Collection.
      @invocations = []
    end

    def call(event, method, property_options, &block) # FIXME: as long as we only support method, pass in here.
      send(event, property_options, &block)
      [event, method, @invocations]
    end

    def on_add(state=nil, &block) # how to call it once, for "all"?
      # @twins can only be Collection instance.
      @twins.added.each do |item|
        run!(item, &block) if ! state.is_a?(Symbol)
        run!(item, &block) if item.created? && state == :created # :created # DISCUSS: should we really keep that?
      end
    end

    def on_delete(*, &block)
      # @twins can only be Collection instance.
      @twins.deleted.each do |item|
        run!(item, &block)
      end
    end

    def on_destroy(*, &block)
      @twins.destroyed.each do |item|
        run!(item, &block)
      end
    end

    def on_update(*, &block)
      @twins.each do |twin|
        next if twin.created?
        next unless twin.persisted? # only persisted can be updated.
        next unless twin.changed?
        run!(twin, &block)
      end
    end

    def on_create(*, &block)
      @twins.each do |twin|
        next unless twin.created?
        run!(twin, &block)
      end
    end

    def on_change(property_options={}, &block)
      name = property_options[:property]

      @twins.each do |twin|
        if name
          run!(twin, &block) if twin.changed?(name)
          next
        end

        next unless twin.changed?
        run!(twin, &block)
      end
    end

  private
    def run!(twin, &block)
      yield(twin).tap do |res|
        @invocations << twin
      end
    end
  end
end
