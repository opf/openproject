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
  class ThisWeek < Base
    label 'this_week'
    set_symbol 'w'
    require_value false

    def self.sql_for_field(_values, db_table, db_field)
      from = begin_of_week
      "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [
        connection.quoted_date(from), connection.quoted_date(from + 7.days)
      ]
    end

    def self.begin_of_week
      if I18n.t(:general_first_day_of_week) == '7'
        # week starts on sunday
        if Date.today.cwday == 7
          Time.now.at_beginning_of_day
        else
          Time.now.at_beginning_of_week - 1.day
        end
      else
        # week starts on monday (Rails default)
        Time.now.at_beginning_of_week
      end
    end
  end
end
