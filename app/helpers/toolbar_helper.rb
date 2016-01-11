module ToolbarHelper
  include ERB::Util

  def toolbar(title:, subtitle: '', link_to: nil, html: {})
    classes = ['toolbar-container', html[:class]].compact.join(' ')
    content_tag :div, class: classes do
      toolbar = content_tag :div, class: 'toolbar' do
        dom_title(title, link_to) + dom_toolbar {
          yield if block_given?
        }
      end
      next toolbar if subtitle.blank?
      toolbar + content_tag(:p, subtitle, class: 'subtitle')
    end
  end

  protected

  def dom_title(title, link_to = nil)
    content_tag :div, class: 'title-container' do
      if link_to.present?
        content_tag(:h2, "#{h(title)}: #{link_to}".html_safe)
      else
        content_tag(:h2, title)
      end
    end
  end

  def dom_toolbar
    return '' unless block_given?
    content_tag :ul, class: 'toolbar-items' do
      yield
    end
  end
end
