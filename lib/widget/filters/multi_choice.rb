class Widget::Filters::MultiChoice < Widget::Filters::Base

  def render
    content_tag :td do
      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        choices = filter_class.available_values.each_with_index.map do |(label, value), i|
          radio_button = tag :input,
            :type => "radio", :name => "#{filter_class.underscore_name}_arg_1_val",
            :id => "#{filter_class.underscore_name}_radio_option_#{i}",
            :class => "#{filter_class.underscore_name}_radio_option",
            :value => value
          content_tag :label, radio_button + label,
            :for => "#{filter_class.underscore_name}_radio_option_#{i}",
            :'data-filter-name' => filter_class.underscore_name
        end
        choices.join(tag(:br)).html_safe
      end
    end
  end
end
