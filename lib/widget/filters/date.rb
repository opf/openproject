class Widget::Filters::Date < Widget::Filters::Base
  def render
    name = "values[#{filter.underscore_name}][]"
    id_prefix = "#{filter.underscore_name}_"

    content_tag :td do
      content_tag :div, :id => "#{id_prefix}arg_1", :class => "filter_values" do
        text_field_tag name, "", :size => 10, :class => "select-small", :id => "#{id_prefix}arg_1_val"
        calendar_for("#{id_prefix}arg_1_val")
        content_tag :span, :id => "#{id_prefix}arg_2", :class => "between_tags" do
          text_field_tag "#{name}", "", :size => 10, :class => "select-small", :id => "#{id_prefix}arg_2_val"
          calendar_for "#{id_prefix}arg_2_val"
        end
      end
    end
  end
end
