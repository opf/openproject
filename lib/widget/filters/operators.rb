class Widget::Filters::Operators < Widget::Filters::Base
  def render
    content_tag :td, :width => (filter.width || 100) do
      content_tag :select, :class => "select-small filters-select",
                           :style => "vertical-align: top", # FIXME: put into CSS
                           :id => "operators[#{filter.underscore_name}]",
                           :onchange => "operator_changed('#{filter.underscore_name}', this);",
                           :name => "operators[#{filter.underscore_name}]" do
        filter.available_operators.each do |o|
          if filter.operator.to_s = o.to_s
            content_tag :option, :value => h(o.to_s), :data-arity => o.arity, :selected => "selected"  do
              h(l(o.label))
            end
          else
            content_tag :option, :value => h(o.to_s), :data-arity => o.arity do
              h(l(o.label))
            end
          end
        end
      end
    end
  end
end
