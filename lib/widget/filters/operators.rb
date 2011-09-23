
class Widget::Filters::Operators < Widget::Filters::Base
  def render
    write(content_tag :td, :width => 100 do
      hide_select_box = (filter_class.available_operators.count == 1 || filter_class.heavy?)
      options = {:class => "select-small filters-select filter_operator",
                 :style => "vertical-align: top", # FIXME: put into CSS
                 :id => "operators[#{filter_class.underscore_name}]",
                 :name => "operators[#{filter_class.underscore_name}]",
                 :"data-filter-name" => filter_class.underscore_name }
      options.merge! :style => "display: none" if hide_select_box
      select_box = content_tag :select, options do
        filter_class.available_operators.collect do |o|
          opts = {:value => h(o.to_s), :"data-arity" => o.arity}
          opts.reverse_merge! :"data-forced" => o.forced if o.forced?
          opts[:selected] = "selected" if filter.operator.to_s == o.to_s
          content_tag(:option, opts) { h(l(o.label)) }
        end.join.html_safe
      end
      label = content_tag :label do
        if filter_class.available_operators.any?
          l(filter_class.available_operators.first.label)
        end
      end
      hide_select_box ? select_box + label : select_box
    end)
  end
end
