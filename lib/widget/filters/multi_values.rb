class Widget::Filters::MultiValues < Widget::Filters::Base

  def render
    write(content_tag :td do
      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        select_options = {  :"data-remote-url" => url_for(:action => "available_values"),
                            :style => "vertical-align: top;", # FIXME: Do CSS
                            :name => "values[#{filter_class.underscore_name}][]",
                            :"data-loading" => @options[:lazy] ? "ajax" : "",
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
          select_options.merge! :"data-initially-selected" =>
            filter.values.to_json.gsub!('"', "'") || "[" + filter.values.map { |v| "'#{v}'" }.join(',') + "]"
        end
        select_options.merge! :"data-dependent" => true if filter_class.is_dependent?
        box_content = "".html_safe
        label = label_tag "#{filter_class.underscore_name}_arg_1_val",l(:description_filter_selection), :class => 'hidden-for-sighted'
        box = content_tag :select, select_options, :id => "#{filter_class.underscore_name}_select_1" do
            render_widget Widget::Filters::Option, filter, :to => box_content unless @options[:lazy]
        end
        plus = content_tag :a, :href => 'javascript:', :class => "filter_multi-select", :"data-filter-name" => filter_class.underscore_name,
          :title => l(:description_multi_select) do
          image_tag 'bullet_toggle_plus.png', :style => "vertical-align: bottom;"
        end
        label + box + plus
      end
    end)
  end
end
