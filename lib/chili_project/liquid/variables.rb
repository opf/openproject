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
    module Variables
      # Liquid "variables" that are used for backwards compatability with macros
      #
      # Variables are used in liquid like {{var}}
      def self.macro_backwards_compatibility
        {
          'macro_list' => "Use the '{% variable_list %}' tag to see all Liquid variables and '{% tag_list %}' to see all of the Liquid tags."
        }
      end
    end
  end
end
