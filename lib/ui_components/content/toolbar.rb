module UiComponents
  module Content
    class Toolbar < UiComponents::Element
      attr_accessor :items, :scrollable

      role :menubar

      def initialize(attributes = {})
        @items = attributes.fetch :items, []
        super
      end

      private

      def toolbar_items
        @items.map(&:render!).join.html_safe
      end

      def css_classes
        %w(toolbar-items) + Array(super)
      end

      def default_strategy
        -> { content_tag :ul, toolbar_items, html_options }
      end
    end
  end
end
