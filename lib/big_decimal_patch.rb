module BigDecimalPatch
  BigDecimal.send :include, self
  def to_d; self end
end