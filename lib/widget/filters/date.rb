class Widget::Filters::Date < Widget::Filters::Base
  def calendar_for(field_id)
    include_calendar_headers_tags +
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
    javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end

  def include_calendar_headers_tags
    unless @calendar_headers_tags_included
      @calendar_headers_tags_included = true
      content_for :header_tags do
        'Calendar._FD = 1;' # Monday
        javascript_include_tag('calendar/calendar') +
        javascript_include_tag("calendar/lang/calendar-#{current_language.to_s.downcase}.js") +
        javascript_tag('Calendar._FD = 1;') + # Monday
        javascript_include_tag('calendar/calendar-setup') +
        stylesheet_link_tag('calendar')
      end
    end
  end

  def render
    name = "values[#{filter_class.underscore_name}][]"
    id_prefix = "#{filter_class.underscore_name}_"

    write(content_tag :td do
      arg1 = content_tag :span, :id => "#{id_prefix}arg_1", :class => "filter_values" do
        text1 = text_field_tag name, @filter.values.first.to_s, :size => 10, :class => "select-small", :id => "#{id_prefix}arg_1_val"
        cal1 = calendar_for("#{id_prefix}arg_1_val")
        text1 + cal1
      end
      arg2 = content_tag :span, :id => "#{id_prefix}arg_2", :class => "between_tags" do
        text2 = text_field_tag "#{name}", @filter.values.second.to_s, :size => 10, :class => "select-small", :id => "#{id_prefix}arg_2_val"
        cal2 = calendar_for "#{id_prefix}arg_2_val"
        text2 + cal2
      end
      arg1 + arg2
    end)
  end
end
