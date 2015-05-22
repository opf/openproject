module ContentHeaderHelper
  class ContentHeader
    include ActionView::Helpers
    attr_accessor :output_buffer

    def initialize(title:, subtitle: '', helper: nil, &_block)
      @title    = title
      @subtitle = subtitle
      @helper   = helper
    end

    def toolbar(&block)
      content_tag :div, class: 'toolbar-container' do
        header = content_tag :div, id: 'toolbar' do
          dom_title(@title) + content_tag(:ul, items(&block), id: 'toolbar-items')
        end
        next header if @subtitle.blank?
        header + content_tag(:p, @subtitle, class: 'subtitle')
      end
    end

    protected

    def items(&block)
      return @helper.capture(ContentToolbar.new, &block) if block_given?
      ''
    end

    def dom_title(title)
      content_tag :div, class: 'title-container' do
        title_attribute = decode title
        content_tag(:h2, title.html_safe, title: title_attribute)
      end
    end

    def decode(string)
      raw(strip_tags(string)).strip
    end

    class ContentToolbar
      include ActionView::Helpers

      attr_accessor :output_buffer

      def button(text, location, options = {})
        options[:class] = %w(button) + Array(options[:class])
        item text, location, options
      end

      def item(text, location, options = {})
        color, icon, css_classes = [:color, :icon, :class].map { |sym| options.fetch sym, '' }
        css_classes = Array(css_classes) + Array(class_from_color(color))
        return '' unless show?(options)
        toolbar_item do
          link_to location, class: css_classes do
            next button_text(text) if icon.blank?
            button_icon(icon) + button_text(text)
          end
        end
      end

      def toolbar_item(&block)
        content_tag :li, class: 'toolbar-item', &block
      end

      protected

      def button_icon(icon)
        content_tag :i, '', class: "button--icon icon-#{icon}"
      end

      def button_text(text)
        content_tag :span, text, class: 'button--text'
      end

      def show?(options = {})
        options.fetch(:if, true) && !options.fetch(:unless, false)
      end

      def class_from_color(color)
        case color.to_sym
        when :green
          '-alt-highlight'
        when :blue
          '-highlight'
        else
          ''
        end
      end
    end
  end

  def content_header(title:, subtitle: '', &block)
    if block_given?
      capture(ContentHeader.new(title: title, subtitle: subtitle, helper: self), &block)
    else
      ContentHeader.new(title: title, subtitle: subtitle).toolbar
    end
  end
end
