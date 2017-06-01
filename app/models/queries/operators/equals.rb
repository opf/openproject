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

module Queries::Operators
  class Equals < Base
    label 'equals'
    set_symbol '='

    def self.sql_for_field(values, db_table, db_field)
      # code expects strings (e.g. for quoting), but ints would work as well: unify them here
      values = values.map(&:to_s)

      sql = ''

      if values.present?
        if values.include?('-1')
          sql = "#{db_table}.#{db_field} IS NULL OR "
        end

        sql += "#{db_table}.#{db_field} IN (" +
               values.map { |val| "'#{connection.quote_string(val)}'" }.join(',') + ')'
      else
        # empty set of allowed values produces no result
        sql = '0=1'
      end

      sql
    end
  end
end
