#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'

describe CustomActions::CuContract do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:action) do
    FactoryBot.build_stubbed(:custom_action, actions:
                              [CustomActions::Actions::AssignedTo.new])
  end
  let(:instance) { described_class.new(action) }

  describe 'name' do
    it 'is writable' do
      action.name = 'blubs'

      expect(instance.validate)
        .to be_truthy
    end
    it 'needs to be set' do
      action.name = nil

      expect(instance.validate)
        .to be_falsey
    end
  end

  describe 'description' do
    it 'is writable' do
      action.description = 'blubs'

      expect(instance.validate)
        .to be_truthy
    end
  end

  describe 'actions' do
    it 'is writable' do
      responsible_action = CustomActions::Actions::Responsible.new

      action.actions = [responsible_action]

      expect(instance.validate)
        .to be_truthy
    end

    it 'needs to have one' do
      action.actions = []

      instance.validate

      expect(instance.errors.symbols_for(:actions))
        .to eql [:empty]
    end

    it 'requires a value if the action requires one' do
      action.actions = [CustomActions::Actions::Status.new([])]

      instance.validate

      expect(instance.errors.symbols_for(:actions))
        .to eql [:empty]
    end

    it 'allows only the allowed values' do
      status_action = CustomActions::Actions::Status.new([0])
      allow(status_action)
        .to receive(:allowed_values)
        .and_return([{ value: nil, label: '-' },
                     { value: 1, label: 'some status'}])

      action.actions = [status_action]

      instance.validate

      expect(instance.errors.symbols_for(:actions))
        .to eql [:inclusion]
    end

    it 'is not allowed to have an inexistent action' do
      action.actions = [CustomActions::Actions::Inexistent.new]

      instance.validate

      expect(instance.errors.symbols_for(:actions))
        .to eql [:does_not_exist]
    end
  end

  describe 'conditions' do
    it 'is writable' do
      action.conditions = [double('some bogus condition', key: 'some', values: 'bogus', validate: true)]

      expect(instance.validate)
        .to be_truthy
    end

    it 'allows only the allowed values' do
      status_condition = CustomActions::Conditions::Status.new([0])
      allow(status_condition)
        .to receive(:allowed_values)
        .and_return([{ value: nil, label: '-' },
                     { value: 1, label: 'some status'}])

      action.conditions = [status_condition]

      instance.validate

      expect(instance.errors.symbols_for(:conditions))
        .to eql [:inclusion]
    end

    it 'is not allowed to have an inexistent condition' do
      action.conditions = [CustomActions::Conditions::Inexistent.new]

      instance.validate

      expect(instance.errors.symbols_for(:conditions))
        .to eql [:does_not_exist]
    end
  end
end
