#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    module PageSizeHelper
      # Set a default max size to ensure backwards compatibility
      # with the previous private setting `maximum_page_size`.
      # The actual value is taken from
      # max(Setting.per_page_options)
      DEFAULT_API_MAX_SIZE ||= 500

      ##
      # Determine set page_size from string
      def resolve_page_size(string)
        resolved_value = to_i_or_nil(string)
        # a page size of 0 is a magic number for the maximum page size value
        if resolved_value == 0 || resolved_value.to_i > maximum_page_size
          resolved_value = maximum_page_size
        end
        resolved_value
      end

      ##
      # Get the maximum allowed page size from
      # the largest option of per_page size,
      # or the magic fallback value 500.
      def maximum_page_size
        [
          DEFAULT_API_MAX_SIZE,
          Setting.per_page_options_array.max
        ].max
      end

      private

      def to_i_or_nil(string)
        string ? string.to_i : nil
      end
    end
  end
end
