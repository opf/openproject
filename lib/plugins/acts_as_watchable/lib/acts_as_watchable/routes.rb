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

module OpenProject
  module Acts
    module Watchable
      module Routes
        mattr_accessor :models

        def self.matches?(request)
          params = request.path_parameters

          watched?(params[:object_type]) &&
          /\d+/.match(params[:object_id])
        end

        private

        def self.watched?(object)
          self.watchable_object? object
        end

        def self.watchable_object?(object)
          if Object.const_defined? object.to_s.classify
            klass = object.to_s.classify.constantize

            klass.included_modules.include? Redmine::Acts::Watchable
          else
            false
          end
        end
      end
    end
  end
end
