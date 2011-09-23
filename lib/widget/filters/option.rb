##
# Accepts option :content, which expects an enumerable of [name, id, *args]
# as it would appear in a filters available values. If given, it renders the
# option-tags from the content array instead of the filters available values.

class Widget::Filters::Option < Widget::Filters::Base
  def render
    first = true
    write((@options[:content] || filter_class.available_values).collect do |name, id, *args|
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
        content_tag(:option, opts) { name_prefix + name }
      else
        tag :optgroup, :label => l(:label_sector)
      end
    end.join.html_safe)
  end
end
