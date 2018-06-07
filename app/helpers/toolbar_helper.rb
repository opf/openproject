module ToolbarHelper
  include ERB::Util
  include ActionView::Helpers::OutputSafetyHelper

  def toolbar(title:, title_extra: nil, title_class: nil, subtitle: '', link_to: nil, html: {})
    classes = ['toolbar-container', html[:class]].compact.join(' ')
    content_tag :div, class: classes do
      toolbar = content_tag :div, class: 'toolbar' do
        dom_title(title, link_to, title_class: title_class, title_extra: title_extra) + dom_toolbar {
          yield if block_given?
        }
      end
      next toolbar if subtitle.blank?
      toolbar + content_tag(:p, subtitle, class: 'subtitle')
    end
  end

  def breadcrumb_toolbar(*elements, subtitle: '', html: {}, &block)
    toolbar(title: safe_join(elements, ' &raquo '.html_safe), subtitle: subtitle, html: html, &block)
  end

  protected

  def dom_title(raw_title, link_to = nil, title_class: nil, title_extra: nil)
    title = ''.html_safe
    title << raw_title

    if link_to.present?
      title << ': '
      title << link_to
    end

    content_tag :div, class: 'title-container' do
      opts = {}

      opts[:class] = title_class if title_class.present?

      content_tag(:h2, title, opts) + (
        title_extra.present? ? title_extra : ''
      )
    end
  end

  def dom_toolbar
    return '' unless block_given?
    content_tag :ul, class: 'toolbar-items' do
      yield
    end
  end
end
