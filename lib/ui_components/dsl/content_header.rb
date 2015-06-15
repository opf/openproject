module UiComponents
  module Dsl
    module ContentHeader

      def content_header(attributes = {}, &block)
        proxy = HeaderDSL.new(attributes)
        proxy.instance_eval(&block) if block_given?
        proxy.header.render!
      end

      private

      class HeaderDSL

        attr_accessor :header

        def initialize(attributes = {})
          @header = header_class.new attributes
        end

        def toolbar(&block)
          @header.toolbar.items = ToolbarDSL.new.instance_eval(&block)
        end

        private

        def header_class
          UiComponents::Content::Header
        end
      end

      class ToolbarDSL

        attr_accessor :items

        def initialize
          @items = []
        end

        def button(label, path, options)
          button_options = options.merge(text: label, href: path)
          button = button_class.new button_options
          items << item_class.new(element: button)
        end

        def submenu(attributes = {}, &block)
          submenu = submenu_class.new(attributes)
          submenu.items = SubmenuDSL.new.instance_eval(&block)
          items << submenu
        end

        private

        def item_class
          UiComponents::Content::Toolbar::Item
        end

        def button_class
          UiComponents::Content::Button
        end

        def submenu_class
          UiComponents::Content::Toolbar::Submenu
        end

        class SubmenuDSL

          attr_accessor :items

          def initialize
            @items = []
          end

          def submenu_item(label, path, options)
            item_options = options.merge(text: label, href: path)
            items << submenu_item_class.new(item_options)
          end

          def submenu_divider
            items << submenu_item_class.new(divider: true)
          end

          def submenu_item_class
            UiComponents::Content::Toolbar::SubmenuItem
          end
        end
      end
    end
  end
end
