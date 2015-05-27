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
        capture do
          concat header
          concat content_tag(:p, @subtitle, class: 'subtitle')
        end
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

      delegate :key_for, to: OpenProject::AccessKeys

      def button(text, location, options = {})
        options[:class] = %w(button) + Array(options[:class])
        item text, location, options
      end

      def item(text, location, options = {})
        color, icon, css_classes, key = values_from options
        css_classes = Array(css_classes) + Array(class_from_color(color))
        return '' unless show?(options)
        link_options = delete_keys_from(options).merge(class: css_classes, accesskey: key_for(key))
        toolbar_item do
          link_to location, link_options do
            (button_icon(icon) + button_text(text)).html_safe
          end
        end
      end

      def toolbar_item
        if block_given?
          content_tag :li, class: 'toolbar-item' do
            yield
          end
        else
          content_tag :li, '', class: 'toolbar-item'
        end
      end

      protected

      def button_icon(icon)
        return '' if icon.blank?
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
        when :alt
          '-alt-highlight'
        when :default
          '-highlight'
        else
          ''
        end
      end

      def values_from(options)
        [:highlight, :icon, :class, :accesskey].map { |sym| options.fetch sym, '' }
      end

      def delete_keys_from(options)
        keys_to_delete = [:unless, :if, :highlight, :icon, :class, :accesskey]
        options.delete_if { |k, _| keys_to_delete.include? k }
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
