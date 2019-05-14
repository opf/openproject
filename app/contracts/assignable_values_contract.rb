module AssignableValuesContract
  def assignable_values(column, _user)
    method_name = "assignable_#{column.to_s.pluralize}"

    if respond_to?(method_name, true)
      send(method_name)
    end
  end
end
