#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Authorization::Visitor
  class ToS
    def initialize(scope)
      @scope = scope
    end

    def visit(subject)
      send(method_name(subject), subject)
    end

    def visit_Authorization(allowance)
      allowance.to_s
    end

    def visit_Authorization_Table_Base(subject)
      ret = get_table_name(subject)

      subject.joins.each do |join|
        ret += visit(join)
      end

      ret += where_conditions(subject)

      ret
    end

    def visit_Authorization_Join(join)
      ret = if join.type == Arel::Nodes::OuterJoin
               "\nLEFT OUTER JOIN "
             else
               "\nINNER JOIN "
             end

      ret += get_table_name(join.table)

      ret += "\nON " + visit(join.condition)

      ret
    end

    def visit_Authorization_Condition_Base(condition)
      get_condition_name(condition)
    end

    def visit_Authorization_Condition_AndConcatenation(condition)
      first = visit(condition.first)
      second = visit(condition.second)

      "#{first} AND #{second}"
    end

    def visit_Authorization_Condition_OrConcatenation(condition)
      first = visit(condition.first)
      second = visit(condition.second)

      "#{first} OR #{second}"
    end

    private

    attr_reader :scope

    def where_conditions(subject)
      return "" if subject.where_conditions.empty?

      ret = "\nWHERE "

      ret += subject.where_conditions.map do |condition|
        visit(condition)
      end.join(" AND ")

      ret
    end

    def get_condition_name(condition)
      condition.class.to_s
    end

    def get_table_name(table)
      scope.table_name(table).to_s
    end

    def method_name(subject)
      "visit_#{subject.visitor_class.to_s.gsub(/::/,'_')}".intern
    end
  end
end
