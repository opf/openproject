module UiComponents::Content
  class Header < UiComponents::Element
    attr_accessor :scrollable, :subtitle, :title, :toolbar

    def initialize(attributes = {})
      # TODO: content header currenly always gets a toolbar for styling reasons
      @toolbar = attributes[:toolbar] || Toolbar.new
      @title   = attributes.fetch :title, ''
      @subtitle = attributes.fetch :subtitle, ''
      @scrollable = attributes.fetch :scrollable, false
      super
    end

    def default_strategy
      -> {
        content_tag :div, class: %w(toolbar-container) do
          capture do
            concat content_tag(:div, title_and_toolbar, class: toolbar_css)
            concat content_tag(:p, subtitle, class: %w(subtitle)) if subtitle.present?
          end
        end
      }
    end

    private

    def toolbar_css
      return %w(toolbar) unless scrollable == true
      %w(toolbar -scrollable)
    end

    def title_and_toolbar
      title = capture do
        content_tag(:div, class: 'title-container') do
          content_tag(:h2, @title, title: @title)
        end
      end
      capture do
        concat title
        concat @toolbar.render!
      end
    end
  end
end
