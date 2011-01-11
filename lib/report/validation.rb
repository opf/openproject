module Report::Validation
  extend ProactiveAutoloader
  include Report::QueryUtils
  autoload :Dates, 'report/validation/dates'
  autoload :Integers, 'report/validation/integers'
  autoload :Sql, 'report/validation/sql'

  def register_validations(*validation_methods)
    validation_methods.flatten.each do |val_method|
      register_validation(val_method)
    end
  end

  def register_validation(val_method)
    const_name = val_method.to_s.camelize
    begin
      val_module = Report::Validation.const_get const_name
      singleton_class.send(:include, val_module)
      val_method = "validate_" + val_method.to_s.pluralize
      if method(val_method)
        validations << val_method
      else
        warn "#{val_module.name} does not define #{val_method}"
      end
    rescue NameError
      warn "No Module Report::Validation::#{const_name} found to validate #{val_method}"
    end
    self
  end

  def errors
    @errors ||= Hash.new { |h,k| h[k] = [] }
  end

  def validations
    @validations ||= []
  end

  def validate(*values)
    errors.clear
    return true if validations.empty?
    validations.all? do |validation|
      values.empty? ? true : send(validation, *values)
    end
  end

end
