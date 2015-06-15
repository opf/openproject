module UiComponents
  module Content
    class Button < UiComponents::Element
      include UiComponents::Linkable

      attr_accessor :highlight

      role :button

      def initialize(attributes = {})
        @highlight = attributes.fetch :highlight, nil
        tag attributes
        text! attributes
        icon! attributes
        super
      end

      protected

      def css_classes
        %w(button) + highlight + Array(super)
      end

      def highlight
        case @highlight
        when :alt, 'alt'
          %w(-alt-highlight)
        when :default, 'default'
          %w(-highlight)
        else
          %w()
        end
      end

      def default_strategy
        -> {
          content_tag :a, icon_and_text, html_options
        }
      end
    end
  end
end
