#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'

describe Settings::UpdateService do
  let(:instance) do
    described_class.new(user:, contract_options:)
  end
  let(:user) { build_stubbed(:user) }
  let(:contract_options) { {} }
  let(:contract) do
    instance_double(Settings::UpdateContract,
                    validate: contract_success,
                    errors: instance_double(ActiveModel::Error))
  end
  let(:contract_success) { true }
  let(:setting_definition) do
    instance_double(Settings::Definition,
                    on_change: definition_on_change)
  end
  let(:definition_on_change) do
    instance_double(Proc,
                    call: nil)
  end
  let(:setting_name) { :a_setting_name }
  let(:new_setting_value) { 'a_new_setting_value' }
  let(:previous_setting_value) { 'the_previous_setting_value' }
  let(:params) { { setting_name => new_setting_value } }

  before do
    # stub a setting definition
    allow(Settings::Definition)
      .to receive(:[])
            .and_call_original
    allow(Settings::Definition)
      .to receive(:[])
            .with(setting_name)
            .and_return(setting_definition)
    allow(Setting)
      .to receive(:[])
          .and_call_original
    allow(Setting)
      .to receive(:[]).with(setting_name)
          .and_return(previous_setting_value)
    allow(Setting)
      .to receive(:[]=)

    # stub contract
    allow(Settings::UpdateContract)
      .to receive(:new)
          .and_return(contract)
  end

  describe '#call' do
    shared_examples_for 'successful call' do
      it 'is successful' do
        expect(instance.call(params))
          .to be_success
      end

      it 'sets the setting value' do
        instance.call(params)

        expect(Setting)
          .to have_received(:[]=)
              .with(setting_name, new_setting_value)
      end

      it 'calls the on_change handler' do
        instance.call(params)

        expect(definition_on_change)
          .to have_received(:call).with(previous_setting_value)
      end
    end

    shared_examples_for 'unsuccessful call' do
      it 'is not successful' do
        expect(instance.call(params))
          .not_to be_success
      end

      it 'does not set the setting value' do
        instance.call(params)

        expect(Setting)
          .not_to have_received(:[]=)
      end

      it 'does not call the on_change handler' do
        instance.call(params)

        expect(definition_on_change)
          .not_to have_received(:call)
      end
    end

    include_examples 'successful call'

    context 'when the contract is not successfully validated' do
      let(:contract_success) { false }

      include_examples 'unsuccessful call'
    end

    context 'with a provided params_contract' do
      let(:contract_options) { { params_contract: ParamsContract } }
      let(:params_contract) do
        instance_double(ParamsContract,
                        valid?: params_contract_success,
                        errors: instance_double(ActiveModel::Error))
      end

      before do
        allow(ParamsContract)
        .to receive(:new)
            .and_return(params_contract)
      end

      context 'with a provided params_contract that is successfully validated' do
        let(:params_contract_success) { true }

        include_examples 'successful call'
      end

      context 'with a provided params_contract that fails validation' do
        let(:params_contract_success) { false }

        include_examples 'unsuccessful call'
      end
    end
  end
end
