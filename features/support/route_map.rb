class RouteMap
  def self.register(model, route)
    @map ||= {}

    @map[model] = route
  end


  def self.route(model)
    @map ||= {}

    @map[model] || "/#{model.to_s.underscore.pluralize}"
  end
end
