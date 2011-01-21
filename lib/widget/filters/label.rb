class Widget::Filters::Label < Widget::Filters::Base
  def render
<<<<<<< HEAD
    content_tag :td, :width => 150 do
      content_tag :label, :id => filter_class.underscore_name do
        l(filter_class.label)
=======
    content_tag :td, :width => (filter.width || 150) do
      content_tag :label, :id => filter.underscore_name do
        l(filter.label)
>>>>>>> origin/feature/widgets
      end
    end
  end
end
