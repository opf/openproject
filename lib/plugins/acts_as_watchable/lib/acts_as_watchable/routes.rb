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
          self.models ||= []

          self.models << watched.to_s unless self.models.include?(watched.to_s)

          @watchregexp = Regexp.new(self.models.join("|"))
        end

        private

        def self.watched?(object)
          objects_base_klass = get_objects_base_class object

          @watchregexp.present? && @watchregexp.match(objects_base_klass.table_name).present?
        end

        def self.get_objects_base_class(object)
          klass = object.classify.constantize
          ancestor = klass.ancestors.find_all { |i| i.is_a? Class and i != klass }[0]

          (ancestor == ActiveRecord::Base) ? klass : ancestor
        end
      end
    end
  end
end
