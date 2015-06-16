module UiComponents
  module Content
    class Toolbar
      class Submenu < Item
        attr_accessor :items, :icon, :title, :last

        aria haspopup: true
        role :menuitem

        def initialize(attributes = {})
          @items = attributes.fetch :items, []
          @icon = attributes.fetch :icon, nil
          @title = attributes.fetch :title, ''
          @last = attributes.fetch :last, false
          @href = '#'
          super
        end

        private

        # submenu gets custom options (html options go to the link)
        def css_classes
          []
        end

        def last_modifier
          return [] unless last
          %w(-last)
        end

        def link_and_submenu
          capture do
            concat content_tag(:a, text_and_icons, link_options)
            concat submenu
          end
        end

        def text_and_icons
          capture do
            concat content_tag(:i, '', class: "button--icon icon-#{icon}") if icon
            concat content_tag(:span, title, class: %w(button--text))
            concat content_tag(:i, '', class: 'button--dropdown-indicator')
          end
        end

        def submenu
          css = %w(toolbar-submenu) + last_modifier
          content_tag :ul, submenu_items, class: css, role: :menu, :'aria-hidden' => true
        end

        def submenu_items
          items.map(&:render!).join.html_safe
        end

        def submenu_options
          html_options.merge(
            class: %w(toolbar-item -with-submenu)
          ).delete_if do |k, _|
            [:accesskey].include? k
          end
        end

        def link_options
          {
            class: %w(button),
            href: @href,
            accesskey: determine_accesskey
          }
        end

        def default_strategy
          -> {
            content_tag :li, link_and_submenu, submenu_options
          }
        end
      end
    end
  end
end
