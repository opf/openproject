class Widget::Filters::Label < Widget::Filters::Base
  def render
    content_tag :td, :width => 150 do
      content_tag :label, :id => filter_class.underscore_name do
        l(filter_class.label)
      end
    end
  end
end
