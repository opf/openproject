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

describe CustomActions::UpdateService do
  let(:action) do
    action = FactoryBot.build_stubbed(:custom_action)

    allow(action)
      .to receive(:save)
      .and_return(save_success)

    action
  end
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:save_success) { true }
  let(:contract_success) { true }
  let(:contract_errors) { double('contract errors') }
  let(:instance) do
    contract
    described_class.new(action: action, user: user)
  end
  let(:contract) do
    contract_instance = double('contract instance')

    allow(CustomActions::CuContract)
      .to receive(:new)
      .with(action)
      .and_return(contract_instance)

    allow(contract_instance)
      .to receive(:validate)
      .and_return(contract_success)
    allow(contract_instance)
      .to receive(:errors)
      .and_return(contract_errors)

    contract_instance
  end

  describe '#call' do
    it 'is successful' do
      expect(instance.call(attributes: {}))
        .to be_success
    end

    it 'is has the action in the result' do
      expect(instance.call(attributes: {}).result)
        .to eql action
    end

    it 'yields the result' do
      yielded = false

      proc = Proc.new do |call|
        yielded = call
      end

      instance.call(attributes: {}, &proc)

      expect(yielded)
        .to be_success
    end

    context 'unsuccessful saving' do
      let(:save_success) { false }

      it 'yields the result' do
        yielded = false

        proc = Proc.new do |call|
          yielded = call
        end

        instance.call(attributes: {}, &proc)

        expect(yielded)
          .to be_failure
      end
    end

    context 'unsuccessful contract' do
      let(:contract_success) { false }

      it 'yields the result' do
        yielded = false

        proc = Proc.new do |call|
          yielded = call
        end

        instance.call(attributes: {}, &proc)

        expect(yielded)
          .to be_failure
      end
    end

    it 'sets the name of the action' do
      expect(instance.call(attributes: { name: 'new name' }).result.name)
        .to eql 'new name'
    end

    it 'updates the actions' do
      action.actions = [CustomActions::Actions::AssignedTo.new('1'),
                        CustomActions::Actions::Status.new('3')]

      new_actions = instance
                    .call(attributes: { actions: { assigned_to: ['2'], priority: ['3'] } })
                    .result
                    .actions
                    .map { |a| [a.key, a.values] }

      expect(new_actions)
        .to match_array [[:assigned_to, [2]], [:priority, [3]]]
    end

    it 'handles unknown actions' do
      new_actions = instance
                    .call(attributes: { actions: { some_bogus_name: ['3'] } })
                    .result
                    .actions
                    .map { |a| [a.key, a.values] }

      expect(new_actions)
        .to match_array [[:inexistent, ['3']]]
    end

    it 'updates the conditions' do
      old_status = FactoryBot.create(:status)
      new_status = FactoryBot.create(:status)

      action.conditions = [CustomActions::Conditions::Status.new(old_status.id)]

      new_conditions = instance
                       .call(attributes: { conditions: { status: new_status.id } })
                       .result
                       .conditions
                       .map { |a| [a.key, a.values] }

      expect(new_conditions)
        .to match_array [[:status, [new_status.id]]]
    end

    it 'handles unknown conditions' do
      new_conditions = instance
                       .call(attributes: { conditions: { some_bogus_name: ['3'] } })
                       .result
                       .conditions
                       .map { |a| [a.key, a.values] }

      expect(new_conditions)
        .to match_array [[:inexistent, [3]]]
    end
  end
end
