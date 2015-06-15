module UiComponents
  module Content
    class Toolbar
      class Item < UiComponents::Element
        attr_accessor :element

        role :menuitem

        def initialize(attributes = {})
          @element = attributes.fetch :element, ''
          super
        end

        private

        def content
          return @element.render! if @element.respond_to? :render!
          @element.to_s
        end

        def default_strategy
          -> { content_tag :li, content, html_options }
        end

        def css_classes
          %w(toolbar-item) + Array(super)
        end
      end
    end
  end
end
