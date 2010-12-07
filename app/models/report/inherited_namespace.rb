module Report::InheritedNamespace
  NESTED_NAMESPACES = %w[Validation Filter GroupBy Result Operator]

  def self.activate
    Report.extend self
    NESTED_NAMESPACES.each { |n| n.extend self }
  end

  def const_missing(name, *)
    super
  rescue NameError => error
    load_constant name, error
  end

  def inherited(klass)
    super
    propagate klass
  end
  
  def included(klass)
    super
    propagate klass
  end
  
  def propagate(klass)
    klass.extend Report::InheritedNamespace
    return unless klass < Report
    NESTED_NAMESPACES.each do |name|
      if file = ActiveSupport::Dependencies.search_for_file("#{klass.name}::#{name}".underscore)
        require_or_load file
        klass.const_get(name).extend Report::InheritedNamespace
      else
        const_missing name
      end
    end
  end

  def load_constant(name, error = NameError)
    zuper = (Class === self ? superclass : ancestors.second).const_get(name)
    case zuper
    when Class  then const_set name, Class.new(zuper).extend(Report::InheritedNamespace)
    when Module then const_set name, Module.new { include zuper }.extend(Report::InheritedNamespace)
    else const_set name, zuper
    end
  rescue NameError, ArgumentError => new_error
    error.message << "\n\tWas #{new_error.class}: #{new_error.message}"
    new_error.backtrace[0..9].each { |l| error.message << "\n\t\t#{l}" }
    error.message << "\n\t\t..." if new_error.backtrace.size > 10
    raise error
  end
end
