class Widget::Filters::Label < Widget::Filters::Base
  def render
    content_tag :td, :width => (filter.width || 150) do
      content_tag :label, :id => filter.underscore_name do
        l(filter.label)
      end
    end
  end
end
