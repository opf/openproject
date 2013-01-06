#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
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
          base.class_eval do
            self.filters = base.send(:class_variable_get, '@@filters').values

            class << self
              alias_method_chain :global_filter, :filter_array
              alias_method_chain :create, :filter_array
            end
          end
        end

        module ClassMethods
          def global_filter_with_filter_array(filter)
            raise ArgumentError, "Passed filter is not a module" unless filter.is_a?(Module)
            self.filters += [filter]
          end

          def create_with_filter_array(context)
            strainer = self.new(context)
            filters.each { |filter| strainer.extend(filter) }
            strainer
          end
        end
      end
    end
  end
end
