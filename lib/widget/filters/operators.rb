class Widget::Filters::Operators < Widget::Filters::Base
  def render
    content_tag :td, :width => 100 do
      content_tag :select, :class => "select-small filters-select filter_operator",
                           :style => "vertical-align: top", # FIXME: put into CSS
                           :id => "operators[#{filter_class.underscore_name}]",
                           :name => "operators[#{filter_class.underscore_name}]",
                           :"data-filter-name" => filter_class.underscore_name do
        filter_class.available_operators.collect do |o|
          opts = {:value => h(o.to_s), :"data-arity" => o.arity}
          opts[:selected] = "selected" if filter.operator.to_s == o.to_s
          content_tag(:option, opts) { h(l(o.label)) }
        end.join.html_safe
      end
    end
  end
end
