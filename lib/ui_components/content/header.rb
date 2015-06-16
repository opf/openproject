module UiComponents
  module Content
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
          content_tag :div, html_options_without_title  do
            capture do
              concat content_tag(:div, title_and_toolbar, class: toolbar_css, role: 'navigation')
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

      def css_classes
        %w(toolbar-container)
      end

      def html_options_without_title
        options = html_options.dup
        options.delete :title
        options
      end

      def title_and_toolbar
        title = capture do
          content_tag(:div, class: 'title-container') do
            content_tag(:h2, @title, title: @title, role: :heading)
          end
        end
        capture do
          concat title
          concat @toolbar.render!
        end
      end
    end
  end
end
