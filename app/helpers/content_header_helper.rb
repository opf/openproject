module ContentHeaderHelper
  class AbstractContent
    include ActionView::Helpers
    attr_accessor :output_buffer

    delegate :key_for, to: OpenProject::AccessKeys
  end

  class ContentHeader < AbstractContent
    def initialize(title:, subtitle: '', helper: nil, scrollable: false, &_block)
      @title = title
      @subtitle = subtitle
      @helper = helper
      @scrollable = scrollable
    end

    def toolbar(&block)
      content_tag :div, class: 'toolbar-container' do
        class_name = %w(toolbar)
        class_name += %w(-scrollable) if @scrollable
        header = content_tag :div, class: class_name, role: 'navigation' do
          dom_title(@title) + content_tag(:ul, items(&block), class: 'toolbar-items', role: 'menubar')
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
  end

  class ContentToolbar < AbstractContent
    def initialize
      @tabindex = 0
    end

    def button(text, location, options = {})
      options[:class] = %w(button) + Array(options[:class])
      item text, location, options
    end

    def item(text, location, options = {})
      return '' unless show?(options)
      link_options = extract_from options
      toolbar_item do
        link_to location, link_options.merge(next_tab_index) do
          concat button_icon(options)
          concat button_text(options.merge text: text)
        end
      end
    end

    def toolbar_item(options = {})
      options[:class] = Array(options[:class]) + %w(toolbar-item)
      options[:role] = 'menuitem'
      if block_given?
        content_tag :li, options do
          yield
        end
      else
        content_tag :li, '', options
      end
    end

    def watch_button(object, user, options = {})
      watch_text = options.delete(:watch_text) || I18n.t(:button_watch)
      unwatch_text = options.delete(:unwatch_text) || I18n.t(:button_unwatch)
      return '' if !object.respond_to?(:watched_by?) || user.anonymous?
      watched = object.watched_by?(user)
      text = watched ? unwatch_text : watch_text
      method = watched ? :delete : :post
      icon = watched ? :'not-watch' : :'watch-1'
      additionals = {
        data: {
          remote: true,
          method: method,
          watch_text: watch_text,
          unwatch_text: unwatch_text,
          watch_icon: :'watch-1',
          unwatch_icon: :'not-watch',
          watch_path: watch_path(object, false),
          unwatch_path: watch_path(object, true),
          watch_method: :post,
          unwatch_method: :delete
        },
        icon: icon
      }
      button text, watch_path(object, watched), options.merge(additionals)
    end

    def submenu(options = {}, &block)
      return '' unless show?(options)
      toolbar_item class: '-with-submenu', :'aria-haspopup' => true do
        link_options = extract_from options
        link_options[:class] += %w(button)
        link = link_to('#', link_options.merge(next_tab_index)) do
          concat button_icon options
          concat button_text text: options[:title]
          concat content_tag :i, '', class: 'button--dropdown-indicator'
        end
        concat link
        css = Array(options[:class]) + %w(toolbar-submenu)
        css += %w(-last) if options.delete :last
        concat content_tag :ul, capture(&block), class: css, :'aria-hidden' => true, role: :menu
      end
    end

    def submenu_item(text, location, options = {})
      return '' unless show?(options)
      unless options[:icon]
        options[:class] = Array(options[:class]) + %w(no-icon)
      end
      toolbar_item_options = options.dup.delete_if { |k, _| k == :icon }
      item = toolbar_item(toolbar_item_options.merge(role: :menuitem)) do
        link_options = extract_from(options)
        link_to location, link_options.merge(tabindex: -1) do
          concat content_tag :i, '', class: "icon icon-#{options[:icon]}" if options[:icon]
          concat content_tag :span, text, class: 'button--text'
        end
      end
      concat item
      ''
    end

    def submenu_divider
      item = toolbar_item class: '-divider'
      concat item
      ''
    end

    protected

    def button_icon(options = {})
      icon = options.delete :icon
      return '' if icon.blank?
      content_tag :i, '', class: "button--icon icon-#{icon}"
    end

    def button_text(options = {})
      label_for_blind = options.fetch :label_for_blind, ''
      text = options.fetch :text, ''
      concat content_tag :span, text, class: 'button--text'
      unless label_for_blind.blank?
        concat content_tag(:span, label_for_blind, class: 'hidden-for-sighted')
      end
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

    def extract_from(options = {})
      opts = options.dup
      color, css_classes, key = values_from opts
      css_classes = Array(css_classes) + Array(class_from_color(color))
      delete_keys_from(opts).merge(class: css_classes, accesskey: key_for(key))
    end

    def values_from(options)
      [:highlight, :class, :accesskey].map { |sym| options.fetch sym, '' }
    end

    def delete_keys_from(options)
      keys_to_delete = [:unless, :if, :highlight, :class, :accesskey, :last, :icon]
      options.delete_if { |k, _| keys_to_delete.include? k }
    end

    def watch_path(object, watched)
      path_name = watched ? 'unwatch_path' : 'watch_path'
      url_helpers.send path_name, object_type: object.class.to_s.underscore.pluralize,
                                  object_id: object.id
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def next_tab_index
      @tabindex += 1
      { tabindex: @tabindex }
    end
  end

  def content_header(title:, subtitle: '', scrollable: false, &block)
    if block_given?
      capture(ContentHeader.new(title: title, subtitle: subtitle, helper: self, scrollable: scrollable), &block)
    else
      ContentHeader.new(title: title, subtitle: subtitle, scrollable: scrollable).toolbar
    end
  end
end
