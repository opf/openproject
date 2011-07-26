
class Widget::Filters::MultiValues < Widget::Filters::Base

  def render
    write(content_tag :td do
      content_tag :div, :id => "#{filter_class.underscore_name}_arg_1", :class => "filter_values" do
        select_options = {  :style => "vertical-align: top;", # FIXME: Do CSS
                            :name => "values[#{filter_class.underscore_name}][]",
                            :id => "#{filter_class.underscore_name}_arg_1_val",
                            :class => "select-small filters-select",
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
        if filter_class.is_dependent? && !Array(filter.values).empty?
          select_options.merge! :"data-initially-selected" => filter.values.to_json.gsub!('"', "'")
        end
        box = content_tag :select, select_options do
          first = true
          filter_class.available_values.collect do |name, id, *args|
            options = args.first || {} # optional configuration for values
            level = options[:level] # nesting_level is optional for values
            name = l(name) if name.is_a? Symbol
            name = name.empty? ? l(:label_none) : name
            name_prefix = ((level && level > 0) ? (' ' * 2 * level + '> ') : '')
            unless options[:optgroup]
              opts = { :value => id }
              if (Array(filter.values).map{ |val| val.to_s }.include? id.to_s) || (first && Array(filter.values).empty?)
                opts[:selected] = "selected"
              end
              first = false
              # TODO: The following line was escaping some parts of the name. I
              # don't exatly know why, but it was causing double escaping bugs
              # in a Rails 3 context. Maybe this is needed for Rails 2. I don't
              # know. Please review and remove this comment if feasible.
              #
              # content_tag(:option, opts) { name_prefix + h(name) }
              content_tag(:option, opts) { name_prefix + name }
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
    end)
  end
end
