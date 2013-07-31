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

class InstanceFinder
  def self.register(model, method)
    @model_method_map ||= {}

    @model_method_map[model] = method
  end

  def self.find(model, identifier)
    if @model_method_map[model].nil?
      raise "#{model} is not registerd with InstanceFinder"
    end

    @model_method_map[model].call(identifier)
  end
end
