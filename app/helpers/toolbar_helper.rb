module ToolbarHelper
  def toolbar(title:, subtitle: '', html: {})
    classes = ['toolbar-container', html[:class]].compact.join(' ')
    content_tag :div, class: classes do
      toolbar = content_tag :div, class: 'toolbar' do
        dom_title(title) + dom_toolbar {
          yield if block_given?
        }
      end
      next toolbar if subtitle.blank?
      toolbar + content_tag(:p, subtitle, class: 'subtitle')
    end
  end

  protected

  def dom_title(title)
    content_tag :div, class: 'title-container' do
      content_tag(:h2, title)
    end
  end

  def dom_toolbar
    return '' unless block_given?
    content_tag :ul, class: 'toolbar-items' do
      yield
    end
  end
end
