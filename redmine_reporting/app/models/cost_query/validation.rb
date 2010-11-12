module CostQuery::Validation
  def register_validations(*validation_methods)
    validation_methods.flatten.each do |val_method|
      register_validation(val_method)
    end
  end
  
  def register_validation(val_method)
    const_name = val_method.to_s.camelize
    begin
      val_module = CostQuery::Validation.const_get const_name
      metaclass.send(:include, val_module)
      val_method = "validate_" + val_method.to_s.pluralize
      if method(val_method)
        validations << val_method
      else
        warn "#{val_module.name} does not define #{val_method}"
      end
    rescue NameError
      warn "No Module CostQuery::Validation::#{const_name} found to validate #{val_method}"
    end
    self
  end

  def errors
    @errors ||= []
    @errors
  end

  def validations
    @validations ||= []
    @validations
  end

  def validate(*values)
    errors.clear
    return true if validations.empty?
    validations.all? do |validation|
      values.empty? ? true : send(validation, *values)
    end
  end

end