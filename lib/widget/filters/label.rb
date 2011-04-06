
class Widget::Filters::Label < Widget::Filters::Base
  def render
    write(content_tag :td, :width => 150 do
      options = { :id => filter_class.underscore_name }
      if (engine::Filter.all.any? {|f| f.dependent == filter_class})
        options.merge! :class => 'dependent-filter-label'
      end
      content_tag :label, options do
        l(filter_class.label)
      end
    end)
  end
end
