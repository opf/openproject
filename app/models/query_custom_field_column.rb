class QueryCustomFieldColumn < QueryColumn

  def initialize(custom_field)
    self.name = "cf_#{custom_field.id}".to_sym
    self.sortable = custom_field.order_statement || false
    if %w(list date bool int).include?(custom_field.field_format)
      self.groupable = custom_field.order_statement
    end
    self.groupable ||= false
    @cf = custom_field
  end

  def caption
    @cf.name
  end

  def custom_field
    @cf
  end

  def value(issue)
    cv = issue.custom_values.detect {|v| v.custom_field_id == @cf.id}
    cv && @cf.cast_value(cv.value)
  end
end

