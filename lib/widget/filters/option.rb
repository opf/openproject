class Widget::Filters::Option < Widget::Filters::Base

  def render
    first = true
    write(filter_class.available_values.collect do |name, id, *args|
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
    end.join.html_safe)
  end
end
