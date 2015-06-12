module UiComponents
  module Content
    class Toolbar
      class Submenu < Item
        attr_accessor :items, :icon, :text, :last

        def initialize(attributes = {})
          @items = attributes.fetch :items, []
          @icon = attributes.fetch :icon, nil
          @text = attributes.fetch :text, ''
          @last = attributes.fetch :last, false
          @href = '#'
          super
        end

        private

        def css_classes
          Array(super) + %w(-with-submenu)
        end

        def last_modifier
          return [] unless last
          %w(-last)
        end

        def link_and_submenu
          capture do
            concat content_tag(:a, text_and_icons, class: %w(button), href: @href)
            concat submenu
          end
        end

        def text_and_icons
          capture do
            concat content_tag(:i, '', class: "button--icon icon-#{icon}")
            concat content_tag(:span, text, class: %w(button--text))
            concat content_tag(:i, '', class: 'button--dropdown-indicator')
          end
        end

        def submenu
          css = %w(toolbar-submenu) + last_modifier
          content_tag :ul, submenu_items, class: css
        end

        def submenu_items
          items.map(&:render!).join.html_safe
        end

        def default_strategy
          -> {
            content_tag :li, link_and_submenu, html_options
          }
        end
      end
    end
  end
end
