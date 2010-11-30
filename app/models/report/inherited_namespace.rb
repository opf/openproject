module Report::InheritedNamespace
  NESTED_NAMESPACES = %w[Validation Filter GroupBy Result]

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

  def load_constant(name, error = nil)
    zuper = (Class === self ? superclass : ancestors.second).const_get(name)
    case zuper
    when Class  then const_set name, Class.new(zuper).extend(Report::InheritedNamespace)
    when Module then const_set name, Module.new { include zuper }.extend(Report::InheritedNamespace)
    else const_set name, zuper
    end
  rescue NameError, ArgumentError => new_error
    raise error
  end
end
