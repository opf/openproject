#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module Utilities
    module UrlPropsParsingHelper
      ##
      # Determine set page_size from string
      def resolve_page_size(string)
        resolved_value = to_i_or_nil(string)
        # a page size of -1 is a magic number for the maximum page size value
        if resolved_value == -1 || resolved_value.to_i > maximum_page_size
          resolved_value = maximum_page_size
        end
        resolved_value
      end

      ##
      # Determine the page size from the minimum of
      # * the provided value
      # * the page size specified for the relation (per_page)
      # * the minimum of the per page options specified in the settings
      # * the maximum page size
      def resulting_page_size(value, relation = nil)
        [
          resolve_page_size(value) || relation&.base_class&.per_page || Setting.per_page_options_array.min,
          maximum_page_size
        ]
           .map(&:to_i)
           .min
      end

      ##
      # Get the maximum allowed page size from settings
      def maximum_page_size
        Setting.apiv3_max_page_size.to_i
      end

      private

      def to_i_or_nil(string)
        string ? string.to_i : nil
      end

      # Parses a comma separated list of values and turns it into
      # a nested hash. e.g.:
      #  = "a,b/c/d,e,b/f"
      # is turned into:
      #  = { "a" => {}, "e" => {}, "b" => { "c" => { "d" => {} }, "f" => {} } }
      # The order of the values does not matter.
      # It also accepts an array of individual strings, e.g.:
      #  = ["a","b/c/d","e","b/f"]
      def nested_from_csv(value)
        return unless value

        value
          .delete_prefix("[")
          .delete_suffix("]")
          .split(",")
          .map { |path| nested_hash(path.strip.tr("\"'", "").split("/")) }
          .inject({}) { |hash, nested| hash.deep_merge(nested) }
      end

      def nested_hash(path)
        { path[0] => path.length > 1 ? nested_hash(path[1..]) : {} }
      end
    end
  end
end
