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
        include Dsl::Common
        include Dsl::Conditionable

        attr_accessor :header

        def initialize(attributes = {})
          @header = header_class.new attributes
        end

        def toolbar(&block)
          @header.toolbar.items = ToolbarDSL.new.instance_eval(&block) || []
        end

        private

        def header_class
          UiComponents::Content::Header
        end
      end

      class ToolbarDSL
        include Dsl::Common
        include Dsl::Conditionable

        attr_accessor :items

        def initialize
          @items = []
        end

        def button(label, path, options)
          return unless show? options
          button_options = options.merge(text: label, href: path)
          button = button_class.new button_options
          items << item_class.new(element: button)
        end

        def submenu(attributes = {}, &block)
          return unless show? attributes
          submenu = submenu_class.new(attributes)
          submenu.items = SubmenuDSL.new.instance_eval(&block) || []
          items << submenu
        end

        def watch_button(object, user, options = {})
          return unless show? options
          return unless object.respond_to?(:watched_by?)
          return if user.anonymous?
          button = watch_button_class.new({object: object, user: user}.merge(options))
          items << item_class.new(element: button)
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

        def build_watch_button(object, user, options)
          watched = object.watched_by?(user)
          watch_text = options.delete(:watch_text) || I18n.t(:button_watch)
          unwatch_text = options.delete(:unwatch_text) || I18n.t(:button_unwatch)

        end

        class SubmenuDSL
          include Dsl::Common
          include Dsl::Conditionable

          attr_accessor :items

          def initialize
            @items = []
          end

          def submenu_item(label, path, options)
            return unless show? options
            item_options = options.merge(text: label, href: path)
            items << submenu_item_class.new(item_options)
          end

          def submenu_divider(options = {})
            return unless show? options
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
