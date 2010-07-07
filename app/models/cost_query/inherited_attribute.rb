module CostQuery::InheritedAttribute
  def inherited_attribute(*attributes, &block)
      options = attributes.extract_options!
      list    = options[:list]
      default = options[:default]
      uniq    = options[:uniq]
      map     = options[:map] || proc { |e| e }
      default ||= [] if list
      attributes.each do |name|
        define_singleton_method(name) do |*values|
          return get_inherited_attribute(name, default, list, uniq) if values.empty?
          return set_inherited_attribute(name, values.map(&map) + (instance_variable_get("@#{name}") || [])) if list
          raise ArgumentError, "wrong number of arguments (#{values.size} for 1)" if values.size > 1
          set_inherited_attribute name, map.call(values.first)
        end
        define_method(name) { |*values| self.class.send(name, *values) }
      end
    end

    def define_singleton_method(name, &block)
      attr_writer name
      metaclass.class_eval { define_method(name, &block) }
      define_method(name) { instance_variable_get("@#{name}") or metaclass.send(name) }
    end

    def get_inherited_attribute(name, default = nil, list = false, uniq = false)
      return get_inherited_attribute(name, default, list, false).uniq if list and uniq
      result       = instance_variable_get("@#{name}")
      super_result = superclass.get_inherited_attribute(name, default, list) if superclass.respond_to? :get_inherited_attribute
      if result.nil?
        super_result || default
      else
        list && super_result ? result + super_result : result
      end
    end

    def set_inherited_attribute(name, value)
      instance_variable_set "@#{name}", value
    end
end