#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Versions::Scopes
  class OrderBySemverName
    class << self
      def fetch
        Version.reorder semver_sql, :name
      end

      # Returns an sql for ordering which:
      # * Returns a substring from the beginning of the name up until the first alphabetical character e.g. "1.2.3 "
      #   from "1.2.3 ABC"
      # * Replaces all non numerical character groups in that substring by a blank, e.g "1.2.3 " to "1 2 3 "
      # * Splits the result into an array of individual number parts, e.g. "{1, 2, 3, ''}" from "1 2 3 "
      # * removes all empty array items, e.g. "{1, 2, 3}" from "{1, 2, 3, ''}"
      def semver_sql(table_name = Version.table_name)
        sql = <<~SQL
          array_remove(regexp_split_to_array(regexp_replace(substring(#{table_name}.name from '^[^a-zA-Z]+'), '\\D+', ' ', 'g'), ' '), '')::int[]
        SQL

        Arel.sql(sql)
      end
    end
  end
end
