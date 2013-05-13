module BigDecimalPatch
  module BigDecimal
    ::BigDecimal.send :include, self
    def to_d; self end
  end

  module Integer
    ::Integer.send :include, self
    def to_d; to_f.to_d end
  end

  module String
    ::String.send :include, self
    def to_d; ::BigDecimal.new(self) end
  end
  
  module NilClass
    ::NilClass.send :include, self
    def to_d; 0 end
  end
end
