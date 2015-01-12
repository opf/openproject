#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class Report::GroupBy
  module SqlAggregation
    def responsible_for_sql?
      true
    end

    def compute_result
      super.tap { |r| r.important_fields = group_fields }.grouped_by(all_group_fields(false), type, group_fields)
    end

    def sql_statement
      super.tap do |sql|
        define_group sql
        sql.count unless sql.selects.include? 'count'
      end
    end
  end
end
