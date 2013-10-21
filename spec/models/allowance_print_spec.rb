#-- encoding: UTF-8
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

require 'spec_helper'

describe Authorization, "#print" do
  let(:klass) { Authorization }
  let(:instance) { klass.new }

  def clean_print(allowance)
    # we are not interested in the whitespaces
    allowance.print.gsub(/\n\s*/, " ")
  end

  let(:scope_name) { :scope_name }

  after(:each) do
    # Cleanup created scope so it does not interfere with
    # other tests
    Authorization.drop_scope(scope_name) if Authorization.respond_to?(scope_name)
  end

  describe :print do
    let(:table1) {
      mock_table = double('first_model')

      Class.new(Authorization::Table::Base) { table mock_table }
    }
    let(:table2) {
      mock_table = double('second_model')

      Class.new(Authorization::Table::Base) { table mock_table }
    }
    let(:condition1) {
      mock_condition = Class.new(Authorization::Condition::Base) {}

      Object.const_set(:TestCondition1, mock_condition)
    }
    let(:condition2) {
      mock_condition = Class.new(Authorization::Condition::Base) {}

      Object.const_set(:TestCondition2, mock_condition)
    }

    after do
      Object.send(:remove_const, :TestCondition1) if defined?(TestCondition1)
      Object.send(:remove_const, :TestCondition2) if defined?(TestCondition2)
    end

    it 'returns the scope_target table if nothing else is defined' do
      first_table = table1

      allowance = Authorization.scope(scope_name) do
        table :first, first_table

        scope_target first
      end

      expect(clean_print(allowance)).to eq('first')
    end

    it "returns the scope_target table and it's join" do
      first_table = table1
      second_table = table2
      mock_condition = condition1

      allowance = Authorization.scope(scope_name) do
        table :first, first_table
        table :second, second_table

        condition :join_condition, mock_condition

        scope_target first

        first.left_join(second)
             .on(join_condition)
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{condition1.to_s}")
    end

    it "returns the scope_target table and it's and concatenated join" do
      first_table = table1
      second_table = table2
      mock_condition1 = condition1
      mock_condition2 = condition2

      allowance = Authorization.scope(scope_name) do
        table :first, first_table
        table :second, second_table

        condition :join_condition1, mock_condition1
        condition :join_condition2, mock_condition2

        scope_target first

        first.left_join(second)
             .on(join_condition1.and(join_condition2))
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{condition1.to_s} AND #{condition2.to_s}")
    end

    it "returns the scope_target table and it's or concatenated join" do
      first_table = table1
      second_table = table2
      mock_condition1 = condition1
      mock_condition2 = condition2

      allowance = Authorization.scope(scope_name) do
        table :first, first_table
        table :second, second_table

        condition :join_condition1, mock_condition1
        condition :join_condition2, mock_condition2

        scope_target first

        first.left_join(second)
             .on(join_condition1.or(join_condition2))
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{condition1.to_s} OR #{condition2.to_s}")
    end

    it "returns the scope_target's where condition if defined" do
      first_table = table1
      mock_condition = condition1

      allowance = Authorization.scope(scope_name) do
        table :first, first_table

        condition :where_condition, mock_condition

        scope_target first

        first.where(where_condition)
      end

      expect(clean_print(allowance)).to eq("first WHERE #{condition1.to_s}")
    end

    it "returns the scope_target's and concatenated where condition if defined" do
      first_table = table1
      mock_condition1 = condition1
      mock_condition2 = condition2

      allowance = Authorization.scope(scope_name) do
        table :first, first_table

        condition :where_condition1, mock_condition1
        condition :where_condition2, mock_condition2
        condition :concat, where_condition1.and(where_condition2)

        scope_target first

        first.where(concat)
      end

      expect(clean_print(allowance)).to eq("first WHERE #{condition1.to_s} AND #{condition2.to_s}")
    end

    it "returns the scope_target's or concatenated where condition if defined" do
      first_table = table1
      mock_condition1 = condition1
      mock_condition2 = condition2

      allowance = Authorization.scope(scope_name) do
        table :first, first_table

        condition :where_condition1, mock_condition1
        condition :where_condition2, mock_condition2
        condition :concat, where_condition1.or(where_condition2)

        scope_target first

        first.where(concat)
      end

      expect(clean_print(allowance)).to eq("first WHERE #{condition1.to_s} OR #{condition2.to_s}")
    end
  end
end
