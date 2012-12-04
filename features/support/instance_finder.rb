class InstanceFinder
  def self.register(model, method)
    @model_method_map ||= {}

    @model_method_map[model] = method
  end

  def self.find(model, identifier)
    instance = @model_method_map[model].call(identifier)
  end
end
