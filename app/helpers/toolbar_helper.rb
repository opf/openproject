module ToolbarHelper
  def toolbar(title:, subtitle: '')
    content_tag :div, class: 'toolbar-container' do
      toolbar = content_tag :div, id: 'toolbar' do
        dom_title(title) + dom_toolbar do
          yield if block_given?
        end
      end
      next toolbar if subtitle.blank?
      toolbar + content_tag(:p, subtitle, class: 'subtitle')
    end
  end

  protected

  def dom_title(title)
    content_tag :div, class: 'title-container' do
      title_attribute = decode title
      content_tag(:h2, title.html_safe, title: title_attribute)
    end
  end

  def dom_toolbar
    return '' unless block_given?
    content_tag :ul, id: 'toolbar-items' do
      yield
    end
  end

  def decode(string)
    raw(strip_tags(string)).strip
  end
end
