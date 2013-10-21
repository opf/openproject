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

describe Authorization, '#alter_condition' do
  let(:klass) { Authorization }
  let(:instance) { klass.new }

  def clean_print(allowance)
    # we are not interested in the whitespaces
    allowance.print.gsub(/\n\s*/, " ")
  end

  let(:scope_name) { :test_scope }

  after(:each) do
    # Cleanup created scope so it does not interfere with
    # other tests
    Authorization.drop_scope(scope_name) if Authorization.respond_to?(scope_name)
  end

  describe :alter_condition do
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
    let(:condition3) {
      mock_condition = Class.new(Authorization::Condition::Base) {}

      Object.const_set(:TestCondition3, mock_condition)
    }

    after do
      Object.send(:remove_const, :TestCondition1) if defined?(TestCondition1)
      Object.send(:remove_const, :TestCondition2) if defined?(TestCondition2)
      Object.send(:remove_const, :TestCondition3) if defined?(TestCondition3)
    end

    it 'replaces the condition with another' do
      orig_condition = condition1
      new_condition = condition2
      first_table = table1

      allowance = Authorization.scope(scope_name) do
        condition :my_condition, orig_condition

        table :first, first_table
        scope_target first

        alter_condition :my_condition, new_condition
      end

      expect(allowance.my_condition.class).to eq new_condition
    end

    it 'replaces the condition in a join statement with another' do
      first_table = table1
      second_table = table2
      orig_condition = condition1
      new_condition = condition2

      allowance = Authorization.scope(scope_name) do
        condition :my_condition, orig_condition

        table :first, first_table
        table :second, second_table

        first.left_join(second)
             .on(my_condition)

        scope_target first

        alter_condition :my_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{condition2.to_s}")
    end

    it 'replaces the condition in a join statement with another instance' do
      first_table = table1
      second_table = table2
      orig_condition = condition1
      new_condition = condition2

      allowance = Authorization.scope(scope_name) do
        condition :my_condition, orig_condition
        condition :replacement_condition, new_condition

        table :first, first_table
        table :second, second_table

        first.left_join(second)
             .on(my_condition)

        scope_target first

        alter_condition :my_condition, replacement_condition
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{condition2.to_s}")
    end

    it 'replaces the matched where condition' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition

        table :first, first_table

        first.where(where_condition)

        scope_target first

        alter_condition :where_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{new_condition.to_s}")
    end

    it 'replaces the matched condition when it is part of an and concatenated where condition' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.and(a_condition)

        table :first, first_table

        first.where(concat)

        scope_target first

        alter_condition :where_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{new_condition.to_s} AND #{other_condition.to_s}")
    end

    it 'replaces the matched condition when it is part of an or concatenated where condition' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.or(a_condition)

        table :first, first_table

        first.where(concat)

        scope_target first

        alter_condition :where_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{new_condition.to_s} OR #{other_condition.to_s}")
    end

    it 'replaces the matched or concatenation condition in where' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.or(a_condition)

        table :first, first_table

        first.where(concat)

        scope_target first

        alter_condition :concat, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{new_condition.to_s}")
    end

    it 'replaces the matched and concatenation condition in where' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.and(a_condition)

        table :first, first_table

        first.where(concat)

        scope_target first

        alter_condition :concat, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{new_condition.to_s}")
    end

    it 'replaces the matched and concatenation condition in on' do
      first_table = table1
      second_table = table2
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.and(a_condition)

        table :first, first_table
        table :second, second_table

        first.left_join(second)
             .on(concat)

        scope_target first

        alter_condition :concat, new_condition
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{new_condition.to_s}")
    end

    it 'replaces the matched or concatenation condition in on' do
      first_table = table1
      second_table = table2
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, orig_condition
        condition :a_condition, other_condition
        condition :concat, where_condition.or(a_condition)

        table :first, first_table
        table :second, second_table

        first.left_join(second)
             .on(concat)

        scope_target first

        alter_condition :concat, new_condition
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{new_condition.to_s}")
    end


    it 'simply redefines the condition and leaves the other on condition alone' do
      first_table = table1
      second_table = table2
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :join_condition, other_condition
        condition :a_condition, orig_condition

        table :first, first_table
        table :second, second_table

        first.left_join(second)
             .on(join_condition)

        scope_target first

        alter_condition :a_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first LEFT OUTER JOIN second ON #{other_condition.to_s}")
    end

    it 'simply redefines the condition and leaves the other where condition alone' do
      first_table = table1
      orig_condition = condition1
      new_condition = condition2
      other_condition = condition3

      allowance = Authorization.scope(scope_name) do
        condition :where_condition, other_condition
        condition :a_condition, orig_condition

        table :first, first_table

        first.where(where_condition)

        scope_target first

        alter_condition :a_condition, new_condition
      end

      expect(clean_print(allowance)).to eq("first WHERE #{other_condition.to_s}")
    end


  end
end
