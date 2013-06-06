#make sure to require Widget::Filters::Base first because otherwise
#ruby might find Base within Widget and Rails will not load it
require_dependency 'widget/filters/base'
class Widget::Filters::TextBox < Widget::Filters::Base
  def render
    write(content_tag(:td) do

      label = content_tag :label,
                          h(l(filter_class.underscore_name)) + " " + l(:label_filter_value),
                          :for => "#{filter_class.underscore_name}_arg_1_val",
                          :class => 'hidden-for-sighted'

      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        label + text_field_tag("values[#{filter_class.underscore_name}]", "",
            :size => "6",
            :class => "select-small",
            :id => "#{filter_class.underscore_name}_arg_1_val",
            :'data-filter-name' => filter_class.underscore_name)
      end
    end)
  end
end
