class Widget::Filters::MultiChoice < Widget::Filters::Base

  def render
    content_tag :td do
      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        text_field_tag("values[#{filter_class.underscore_name}]", "",
            :size => "6",
            :class => "select-small",
            :id => "#{filter_class.underscore_name}_arg_1_val",
            :'data-filter-name' => filter_class.underscore_name)
      end
    end
  end
end
