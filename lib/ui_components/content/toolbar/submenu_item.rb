module UiComponents
  module Content
    class Toolbar
      # TODO: this might be semantical BS and should be a concern instead
      class SubmenuItem < Item
        include UiComponents::Linkable

        attr_accessor :divider

        def initialize(attributes = {})
          icon! attributes
          text! attributes
          @divider = attributes.fetch :divider, false
          super
        end

        private

        # classes will be attached to the link and not the item
        def css_classes
          super - %w(toolbar-item)
        end

        def no_icon
          return %w(no-icon) if @icon == false
          []
        end

        def default_strategy
          return divider_strategy if divider == true
          -> {
            content_tag :li, { role: :menuitem }.merge(class: %w(toolbar-item) + no_icon) do
              content_tag :a, icon_and_text, html_options
            end
          }
        end

        def divider_strategy
          -> {
            content_tag :li, '', class: %w(toolbar-item -divider), role: :listitem
          }
        end
      end
    end
  end
end
