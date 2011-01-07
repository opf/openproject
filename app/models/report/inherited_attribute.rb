require 'set'

module Report::InheritedAttribute
  def inherited_attribute(*attributes)
      options = attributes.extract_options!
      list    = options[:list]
      merge   = options.include?(:merge) ? options[:merge] : options[:list]
      default = options[:default]
      uniq    = options[:uniq]
      map     = options[:map] || proc { |e| e }
      default ||= [] if list
      attributes.each do |name|
        define_singleton_method(name) do |*values|
          # FIXME: I'm ugly
          return get_inherited_attribute(name, default, list, uniq) if values.empty?
          if list
            old = instance_variable_get("@#{name}") if merge
            old ||= []
            return set_inherited_attribute(name, values.map(&map) + old)
          end
          raise ArgumentError, "wrong number of arguments (#{values.size} for 1)" if values.size > 1
          set_inherited_attribute name, map.call(values.first)
        end
        define_method(name) { |*values| self.class.send(name, *values) }
      end
    end

    alias singleton_class metaclass unless respond_to? :singleton_class

    def define_singleton_method(name, &block)
      singleton_class.send :attr_writer, name
      singleton_class.class_eval { define_method(name, &block) }
      define_method(name) { instance_variable_get("@#{name}") or singleton_class.send(name) }
    end

    def get_inherited_attribute(name, default = nil, list = false, uniq = false)
      return get_inherited_attribute(name, default, list, false).uniq if list and uniq
      result = instance_variable_get("@#{name}")
      super_result = superclass.get_inherited_attribute(name, default, list) if inherit? name
      if result.nil?
        super_result || default
      else
        list && super_result ? result + super_result : result
      end
    end

    def inherit?(name)
      superclass.respond_to? :get_inherited_attribute and not not_inherited.include? name
    end

    def not_inherited
      @not_inherited ||= Set.new
    end

    def dont_inherit(*attributes)
      not_inherited.merge attributes
    end

    def set_inherited_attribute(name, value)
      instance_variable_set "@#{name}", value
    end
end