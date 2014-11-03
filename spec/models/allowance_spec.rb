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

describe Authorization do
  let(:klass) { Authorization }
  let(:instance) { klass.new }

  let(:scope_name) { :test_scope }

  after(:each) do
    # Cleanup created scope so it does not interfere with
    # other tests
    Authorization.drop_scope(scope_name) if Authorization.respond_to?(scope_name)
  end

  describe :scope do

    it 'adds a method on Authorization' do
      expect(Authorization.respond_to?(scope_name)).to be_false

      Authorization.scope(scope_name) {}

      expect(Authorization.respond_to?(scope_name)).to be_true
    end

    it 'returns a new Authorization instance' do
      expect(Authorization.scope(scope_name) {}).to be_a(Authorization)
    end

    it 'evaluates the passed block within a new allowance object' do
      instance = nil

      Authorization.scope(scope_name) do
        instance = self
      end

      expect(instance).to be_a(Authorization)
    end

    it 'returns the same allowance instance if called twice' do
      instance1 = nil
      instance2 = nil

      Authorization.scope(scope_name) do
        instance1 = self
      end

      Authorization.scope(scope_name) do
        instance2 = self
      end

      expect(instance1.object_id).to eq instance2.object_id
    end
  end

  describe :drop_scope do
    it 'removes the defined scope' do
      Authorization.scope(scope_name) {}

      Authorization.drop_scope(scope_name)

      expect(Authorization.respond_to?(scope_name)).to be_false
    end
  end

  describe :condition do
    it 'creates a method that returns an instance of the specified condition class' do
      klass = Class.new(Authorization::Condition::Base) {}

      allowance = Authorization.scope(scope_name) do
        condition :my_condition, klass
      end

      expect(allowance.my_condition).to be_a(klass)
    end

    it 'creates a method that returns the provided instance' do
      instance = nil

      allowance = Authorization.scope(scope_name) do
        instance = (Class.new(Authorization::Condition::Base) {}).new(self)

        condition :my_condition, instance
      end

      expect(allowance.my_condition).to eq instance
    end
  end

  describe :has_table? do
    it 'should be true if the table is defined in the scope' do
      test_scope = Authorization.scope scope_name do
        table :users
      end

      test_scope.has_table?(User).should be_true
    end

    it 'should be false if the table is not defined in the scope' do
      test_scope = Authorization.scope scope_name do
      end

      test_scope.has_table?(User).should be_false
    end
  end
end
