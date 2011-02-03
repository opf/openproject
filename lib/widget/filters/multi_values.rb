class Widget::Filters::MultiValues < Widget::Filters::Base

  def render
    content_tag :td do
      content_tag :div, :id => filter_class.underscore_name, :class => "filter_values" do
        box = content_tag :select, :style => "vertical-align: top;", # FIXME: Do CSS
                             :name => "values[#{filter_class.underscore_name}][]",
                             :id => "#{filter_class.underscore_name}_arg_1_val",
                             :class => "select-small filters-select",
                             :multiple => "multiple" do
                             # multiple will be disabled/enabled later by JavaScript anyhow.
                             # We need to specify multiple here because of an IE6-bug.
          filter_class.available_values.collect do |name, id, *args|
            options = args.first || {} # optional configuration for values
            level = options[:level] # nesting_level is optional for values
            name = l(name) if name.is_a? Symbol
            name_prefix = ((level && level > 0) ? (' ' * 2 * level + '> ') : '')
            unless options[:optgroup]
              opts = { :value => id }
              opts[:selected] = "selected" if filter.values.include? id
              content_tag(:option, opts) { name_prefix + h(name) }
            else
              tag :optgroup, :label => l(:label_sector)
            end
          end.join.html_safe
        end
        plus = image_tag 'bullet_toggle_plus.png',
                  :class => "filter_multi-select",
                  :style => "vertical-align: bottom;",
                  :"data-filter-name" => filter_class.underscore_name
        box + plus
      end
    end
  end
end