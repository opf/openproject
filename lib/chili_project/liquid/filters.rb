#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
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
    module OverriddenFilters
      # These filters are defined in liquid core but are overwritten here
      # to improve on their implementation

      # Split input string into an array of substrings separated by given pattern.
      # Default to whitespace
      def split(input, pattern=nil)
        input.split(pattern)
      end

      def strip_newlines(input)
        input.to_s.gsub(/\r?\n/, '')
      end

      # Add <br /> tags in front of all newlines in input string
      def newline_to_br(input)
        input.to_s.gsub(/(\r?\n)/, "<br />\1")
      end

      # Use the block systax for sub and gsub to prevent interpretation of
      # backreferences
      # See https://gist.github.com/1491437
      def replace(input, string, replacement = '')
        input.to_s.gsub(string){replacement}
      end

      # Replace the first occurrences of a string with another
      def replace_first(input, string, replacement = '')
        input.to_s.sub(string){replacement}
      end
    end

    module Filters
      def default(input, default)
        input.to_s.strip.present? ? input : default
      end

      def strip(input)
        input.to_s.strip
      end
    end

    Template.register_filter(OverriddenFilters)
    Template.register_filter(Filters)
  end
end
