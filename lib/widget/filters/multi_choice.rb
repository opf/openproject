class Widget::Filters::MultiChoice < Widget::Filters::Base

  def render
    content_tag :td do
      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        content = ''
        available_values = filter_class.available_values
        available_values.each_with_index do |(label, value), i|
          label = content_tag :label,
                      :for => "#{filter_class.underscore_name}_radio_option_#{i}",
                      :'data-filter-name' => filter_class.underscore_name do
            radio_button = content_tag :input,
                      :type => 'radio',
                      :name => "#{filter_class.underscore_name}_arg_1_val",
                      :id => "#{filter_class.underscore_name}_radio_option_#{i}",
                      :class => "#{filter_class.underscore_name}_radio_option",
                      :value => value do
              ''
            end
            radio_button + label
          end
          br = (i == available_values.size - 1) ? '' : content_tag(:br) {}
          content += (label + br)
        end
        content.html_safe
      end
    end
  end
end
