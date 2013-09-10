#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.md for more details.
#++

module OpenProject::Plugins
  module LoadDependency
    def self.register(target, *dependencies)

      ActiveSupport.on_load(target) do
        dependencies.each do |dependency|
          require_dependency dependency
        end
      end

    end
  end
end
