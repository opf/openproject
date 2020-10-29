module AttrOptional

  def self.included(klass)
    klass.send :extend, ClassMethods
  end

  module ClassMethods

    def inherited(klass)
      super
      unless optional_attributes.empty?
        klass.attr_optional(*optional_attributes)
      end
    end

    def attr_optional(*keys)
      if defined? undef_required_attributes
        undef_required_attributes(*keys)
      end
      optional_attributes.concat(keys)
      attr_accessor(*keys)
    end

    def attr_optional?(key)
      optional_attributes.include?(key)
    end

    def optional_attributes
      @optional_attributes ||= []
    end

    def undef_optional_attributes(*keys)
      keys.each do |key|
        if attr_optional?(key)
          undef_method key, :"#{key}="
          optional_attributes.delete key
        end
      end
    end

  end

  def optional_attributes
    self.class.optional_attributes
  end

  def attr_optional?(key)
    self.class.attr_optional? key
  end

end
