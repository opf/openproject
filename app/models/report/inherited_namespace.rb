module Report::InheritedNamespace
  def self.activate
    [Report, Report::Validation, Report::Filter, Report::GroupBy, Report::Result].each do |klass|
      extend_object klass
    end
  end

  def const_missing(name, *)
    super
  rescue NameError => error
    raise error unless respond_to? superclass and superclass != self
    begin
      zuper = superclass.const_get(name)
      case zuper
      when Class  then const_set name, Class.new(zuper).extend(InheritedNamespace)
      when Module then const_set name, Module.new { include zuper }.extend(InheritedNamespace)
      else const_set name, zuper
      end
    rescue NameError
      raise error
    end
  end
end
