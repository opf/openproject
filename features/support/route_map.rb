#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
