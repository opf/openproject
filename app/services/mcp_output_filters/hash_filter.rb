# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpOutputFilters
  # Base class for output filters that want to filter on the content of hashes in a result.
  # It will descend into the values of arrays and hashes and call #on_hash for each hash found
  # along the way, allowing for the implementation to modify the given hash along the way.
  class HashFilter
    def filter(hash_or_array)
      case hash_or_array
      when Hash
        filter_hash(hash_or_array)
      when Array
        hash_or_array.each { |value| filter(value) }
      end
    end

    private

    def filter_hash(hash)
      if on_hash(hash)
        hash.each_value { |value| filter(value) }
      end
    end

    # Expected to be overwritten by subclasses and may perform output filtering on the passed hash (e.g. deleting keys).
    # Should return a truthy value to descend further into values of the given hash or false to stop descending here.
    def on_hash(_hash)
      raise SubclassResponsibilityError
    end
  end
end
