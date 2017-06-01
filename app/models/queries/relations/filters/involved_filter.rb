#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries
  module Relations
    module Filters
      ##
      # Filters relations by work package ID in either `from` or `to` position of a relation.
      # For instance:
      #   Given relations [{ from_id: 3, to_id: 7 }, { from_id: 8, to_id: 3}]
      #   filtering by involved=3 would yield both these relations.
      class InvolvedFilter < ::Queries::Relations::Filters::RelationFilter
        def type
          :integer
        end

        def self.key
          :involved
        end

        def where
          integer_values = values.map(&:to_i)

          case operator
          when "="
            ["from_id IN (?) OR to_id IN (?)", integer_values, integer_values]
          when "!"
            ["from_id NOT IN (?) AND to_id NOT IN (?)", integer_values, integer_values]
          end
        end
      end
    end
  end
end
