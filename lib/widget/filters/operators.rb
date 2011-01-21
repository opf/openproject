class Widget::Filters::Operators < Widget::Filters::Base
  def render
    content_tag :td, :width => 100 do
      content_tag :select, :class => "select-small filters-select",
                           :style => "vertical-align: top", # FIXME: put into CSS
                           :id => "operators[#{filter_class.underscore_name}]",
                           :onchange => "operator_changed('#{filter_class.underscore_name}', this);",
                           :name => "operators[#{filter_class.underscore_name}]" do
        filter_class.available_operators.collect do |o|
          if filter.operator.to_s == o.to_s
            content_tag :option, :value => h(o.to_s), :"data-arity" => o.arity, :selected => "selected"  do
              h(l(o.label))
            end
          else
            content_tag :option, :value => h(o.to_s), :"data-arity" => o.arity do
              h(l(o.label))
            end
          end
        end.join.html_safe
      end
    end
  end
end
