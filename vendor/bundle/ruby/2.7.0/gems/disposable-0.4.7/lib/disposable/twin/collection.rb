module Disposable
  class Twin
    # Provides collection semantics like add, delete, and more for twin collections.
    # Tracks additions and deletions in #added and #deleted.
    class Collection < Array
      def self.for_models(twinner, models, *options)
        new(twinner, models.collect { |model| twinner.(model, *options) })
      end

      def initialize(twinner, items)
        super(items)
        @twinner  = twinner # DISCUSS: twin items here?
        @original = items
      end
      attr_reader :original # TODO: test me and rethink me.

      def find_by(options)
        field, value = options.to_a.first
        find { |item| item.send(field).to_s == value.to_s }
      end

      # Note that this expects a model, untwinned.
      def append(model)
        (self << model).last
      end

      # Note that this expects a model, untwinned.
      def <<(model)
        super(twin = @twinner.(model))
        added << twin
        # this will return the model, anyway.
      end

      # Note that this expects a model, untwinned.
      def insert(index, model)
        super(index, twin = @twinner.(model))
        added << twin
        twin
      end

      # Remove an item from a collection. This will not destroy the model.
      def delete(twin)
        super(twin).tap do |res|
          deleted << twin if res
        end
      end

      # Deletes twin from collection and destroys it in #save.
      def destroy(twin)
        delete(twin)
        to_destroy << twin
      end

      def save # only gets called when Collection::Semantics mixed in.
        destroy!
      end

      module Changed
        # FIXME: this should not be included automatically, as Changed is a feature.
        def changed?
          find { |twin| twin.changed? }
        end
      end
      include Changed

      # DISCUSS: am i a public concept, hard-wired into Collection?
      def added
        @added ||= []
      end

      # DISCUSS: am i a public concept, hard-wired into Collection?
      def deleted
        @deleted ||= []
      end

      # DISCUSS: am i a public concept, hard-wired into Collection?
      def destroyed
        @destroyed ||= []
      end

    private
      def to_destroy
        @to_destroy ||= []
      end

      def destroy!
        to_destroy.each do |twin|
          twin.send(:model).destroy
          destroyed << twin
        end
      end


      module Semantics
        def save
          super.tap do
            schema.each(collection: true) do |dfn| # save on every collection.
              send(dfn.getter).save
            end
          end
        end
      end # Semantics.
    end
  end
end
