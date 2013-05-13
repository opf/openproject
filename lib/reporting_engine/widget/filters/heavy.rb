# FIXME: This basically is the MultiValues-Filter, except that we do not show
#        The select-box. This way we allow our JS to pretend this is just another
#        Filter. This is overhead...
#        But well this is again one of those temporary solutions.

class Widget::Filters::Heavy < Widget::Filters::Base

  def render
    write(content_tag :td do
      # TODO: sometimes filter.values is of the form [["3"]] and somtimes ["3"].
      #       (using cost reporting)
      #       this might be a bug - further research would be fine
      values = filter.values.first.is_a?(Array) ? filter.values.first : filter.values
      opts = Array(values).empty? ? [] : values.map{ |i| filter_class.label_for_value(i.to_i) }
      div = content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values hidden" do
        select_options = {  :"data-remote-url" => url_for(:action => "available_values"),
                            :name => "values[#{filter_class.underscore_name}][]",
                            :"data-loading" => "",
                            :id => "#{filter_class.underscore_name}_arg_1_val",
                            :class => "select-small filters-select filter-value",
                            :"data-filter-name" => filter_class.underscore_name,
                            :multiple => "multiple" }
                            # multiple will be disabled/enabled later by JavaScript anyhow.
                            # We need to specify multiple here because of an IE6-bug.
        if filter_class.has_dependent?
          all_dependents = filter_class.all_dependents.map {|d| d.underscore_name}.to_json
          select_options.merge! :"data-all-dependents" => all_dependents.gsub!('"', "'")
          next_dependents = filter_class.dependents.map {|d| d.underscore_name}.to_json
          select_options.merge! :"data-next-dependents" => next_dependents.gsub!('"', "'")
        end
        # store selected value(s) in data-initially-selected if this filter is a dependent
        # of another filter, as we have to restore values manually in the client js
        if (filter_class.is_dependent? || @options[:lazy]) && !Array(filter.values).empty?
          select_options.merge! :"data-initially-selected" => filter.values.to_json.gsub!('"', "'")
        end
        box = content_tag :select, select_options do
          render_widget Widget::Filters::Option, filter, :to => "", :content => opts
        end
        box
      end
      alternate_text = opts.map{ |o| o.first }.join(', ').html_safe
      div + content_tag(:label) do
        alternate_text
      end
    end)
  end
end
