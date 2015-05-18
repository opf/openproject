module ToolbarHelper
  def toolbar(title:, subtitle: '', &block)
    content_tag :div, class: 'toolbar-container' do
      content_tag :div, id: 'toolbar' do
        dom_title(title, subtitle) + dom_toolbar do
          yield if block_given?
        end
      end
    end
  end

  protected

  def dom_title(title, subtitle)
    content_tag :div, class: 'title-container' do
      content_tag(:h2, title, title: title) +
      content_tag(:p, subtitle, class: 'subtitle')
    end
  end

  def dom_toolbar(&block)
    return '' unless block_given?
    content_tag :ul, class: 'toolbar-items' do
      yield
    end
  end
end
