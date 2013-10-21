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
  class ConditionModifier
    def initialize(scope, orig_condition, new_condition)
      @scope = scope
      @orig_condition = orig_condition
      @new_condition = new_condition
    end

    def visit(subject)
      send(method_name(subject), subject)
    end

    def visit_Authorization_Table_Base(table)
      table.joins.each do |join|
        visit(join)
      end

      table.where_conditions.each_with_index do |condition, index|
        table.where_conditions[index] = visit(condition)
      end
    end

    def visit_Authorization_Join(join)
      join.condition = visit(join.condition)
    end

    def visit_Authorization_Condition_Base(condition)
      replace_original_else(condition) do |condition|
        condition
      end
    end

    def visit_Authorization_Condition_AndConcatenation(condition)
      visit_concatenated(condition)
    end

    def visit_Authorization_Condition_OrConcatenation(condition)
      visit_concatenated(condition)
    end

    private

    attr_reader :scope,
                :new_condition,
                :orig_condition

    def method_name(subject)
      "visit_#{subject.visitor_class.to_s.gsub(/::/,'_')}".intern
    end

    def visit_concatenated(condition)
      replace_original_else(condition) do |condition|
        condition.first = visit(condition.first)
        condition.second = visit(condition.second)

        condition
      end
    end

    def replace_original_else(condition, &block)
      if condition == orig_condition
        new_condition
      else
        block.call(condition)
      end
    end
  end
end
