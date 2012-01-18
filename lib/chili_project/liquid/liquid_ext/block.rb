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

module ChiliProject
  module Liquid
    module LiquidExt
      module Block
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.class_eval do
            alias_method_chain :render_all, :cleaned_whitespace_and_cache
          end
        end

        module InstanceMethods
          def render_all_with_cleaned_whitespace_and_cache(list, context)
            # Remove the leading newline in a block's content
            list[0].sub!(/\A\r?\n/, "") if list[0].is_a?(String)

            # prevent caching if there are any potentially active elements
            context.not_cachable! if list.any? { |token| token.respond_to?(:render) }

            render_all_without_cleaned_whitespace_and_cache(list, context)
          end
        end
      end
    end
  end
end