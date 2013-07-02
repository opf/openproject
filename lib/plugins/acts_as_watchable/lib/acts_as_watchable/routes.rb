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

        def self.add_watched(watched)
          objects_base_klass = get_objects_base_class watched

          self.models ||= []

          self.models << ((objects_base_klass.nil?) ? watched.to_s : objects_base_klass.to_s)
        end

        private

        def self.watched?(object)
          objects_base_class = get_objects_base_class object
          matcher = (objects_base_class.nil?) ? object : objects_base_class.to_s

          self.models.include? matcher.to_s
        end

        def self.get_objects_base_class(object)
          klass = get_objects_class object

          if not klass.nil?
            ancestor = klass.lookup_ancestors.last

            (ancestor == ActiveRecord::Base) ? klass : ancestor
          end
        end

        def self.get_objects_class(object)
          if object.is_a? Class
            object
          elsif Object.const_defined? object.classify
            object.classify.constantize
          end
        end
      end
    end
  end
end
