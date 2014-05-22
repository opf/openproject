class CamelCasingStrategy
  def call(property)
    to_camel_case(property)
  end

  private
    def to_camel_case(string)
      return string if string.first == '_'
      string.camelize(:lower)
    end
end
