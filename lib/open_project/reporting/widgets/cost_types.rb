class Widget::CostTypes < Widget::Base
  def render_with_options(options, &block)
    @cost_types = options.delete(:cost_types)
    @selected_type_id = options.delete(:selected_type_id)

    super(options, &block)
  end

  def render
    write contents
  end

  def contents
    content_tag :div do
      available_cost_type_tabs(@subject).map do |id, label|
        type_selection = radio_button_tag("unit", id, id == @selected_type_id)
        type_selection += label_tag "unit_#{id}", h(label)
        type_selection
      end.join("<br />").html_safe
    end
  end
end
