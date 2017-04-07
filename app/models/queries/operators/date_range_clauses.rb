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
  module DateRangeClauses
    # Returns a SQL clause for a date or datetime field for a relative range from
    # the end of the day of yesterday + from until the end of today + to.
    def relative_date_range_clause(table, field, from, to)
      if from
        from_date = Date.today + from
      end
      if to
        to_date = Date.today + to
      end
      date_range_clause(table, field, from_date, to_date)
    end

    # Returns a SQL clause for date or datetime field for an exact range starting
    # at the beginning of the day of from until the end of the day of to
    def date_range_clause(table, field, from, to)
      s = []
      if from
        s << "#{table}.#{field} > '%s'" % [
          connection.quoted_date(from.yesterday.to_time(:utc).end_of_day)
        ]
      end
      if to
        s << "#{table}.#{field} <= '%s'" % [connection.quoted_date(to.to_time(:utc).end_of_day)]
      end
      s.join(' AND ')
    end
  end
end
