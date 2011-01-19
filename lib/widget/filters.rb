class Widget::Filters < Widget::Base
  def render
    @query.engine::Filter.all.collect do |f|
      render_filter f
    end.join
  end

  def render_filter(f)
    Filters::Label.render(f)
    Filters::Operators.render(f)

    return filter.custom_elements if filter.custom_elements?
    return object_elements_with_dependents filter if filter.has_dependents?
    return text_elements filter if engine::Operator.string_operators.all? { |o| filter.available_operators.include? o }
    return date_elements filter if engine::Operator.time_operators.all?   { |o| filter.available_operators.include? o }
    return object_elements filter
  end

  def object_elements_with_dependents(filter)
    object_elements(filter).tap do |elements|
      elements.last[:dependents] = filter.injected_dependents.collect(&:underscore_name)
      elements.last[:name] = :multi_values_with_dependent
    end
  end

  def object_elements(f)
    Filters::MultiValues.render(f)
  end

  def date_elements(filter)
    [
      {:name => :date, :filter_name => filter.underscore_name}]
  end

  def text_elements(filter)
    [
      {:name => :text_box, :filter_name => filter.underscore_name}]
  end
end
