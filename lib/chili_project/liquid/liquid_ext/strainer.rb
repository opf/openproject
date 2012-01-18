#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Required until https://github.com/Shopify/liquid/pull/87 got merged upstream
module ChiliProject
  module Liquid
    module LiquidExt
      module Strainer
        def self.included(base)
          base.extend(ClassMethods)

          base.class_attribute :filters, :instance_reader => false, :instance_writer => false
          base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            self.filters = @@filters.values
          RUBY
        end

        module ClassMethods
          def global_filter(filter)
            raise ArgumentError, "Passed filter is not a module" unless filter.is_a?(Module)
            filters += [filter]
          end

          def create(context)
            strainer = self.new(context)
            filters.each { |filter| strainer.extend(filter) }
            strainer
          end
        end
      end
    end
  end
end
