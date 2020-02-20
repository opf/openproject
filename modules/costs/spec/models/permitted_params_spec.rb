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

require File.expand_path('../../spec_helper', __FILE__)

describe PermittedParams, type: :model do
  let(:user) { FactoryBot.build(:user) }

  shared_examples_for 'allows params' do
    let(:params_key) { defined?(hash_key) ? hash_key : attribute }
    let(:params) do
      nested_params = if defined?(nested_key)
                        { nested_key => hash }
                      else
                        hash
                      end

      ac_params = if defined?(flat) && flat
                    nested_params
                  else
                    { params_key => nested_params }
                  end

      ActionController::Parameters.new(ac_params)
    end

    subject { PermittedParams.new(params, user).send(attribute).to_h }

    it do
      expected = defined?(allowed_params) ? allowed_params : hash
      expect(subject).to eq(expected)
    end
  end

  describe '#cost_entry' do
    let(:attribute) { :cost_entry }

    context 'comments' do
      let(:hash) { { 'comments' => 'blubs' } }

      it_behaves_like 'allows params'
    end

    context 'units' do
      let(:hash) { { 'units' => '5.0' } }

      it_behaves_like 'allows params'
    end

    context 'overridden_costs' do
      let(:hash) { { 'overridden_costs' => '5.0' } }

      it_behaves_like 'allows params'
    end

    context 'spent_on' do
      let(:hash) { { 'spent_on' => Date.today.to_s } }

      it_behaves_like 'allows params'
    end

    context 'project_id' do
      let(:hash) { { 'project_id' => 42 } }

      it_behaves_like 'allows params' do
        let(:allowed_params) { {} }
      end
    end
  end

  describe '#cost_object' do
    let(:attribute) { :cost_object }

    context 'subject' do
      let(:hash) { { 'subject' => 'subject_test' } }

      it_behaves_like 'allows params'
    end

    context 'description' do
      let(:hash) { { 'description' => 'description_test' } }

      it_behaves_like 'allows params'
    end

    context 'fixed_date' do
      let(:hash) { { 'fixed_date' => '2017-03-01' } }

      it_behaves_like 'allows params'
    end

    context 'project_id' do
      let(:hash) { { 'project_id' => 42 } }

      it_behaves_like 'allows params' do
        let(:allowed_params) { {} }
      end
    end

    context 'existing material budget item' do
      let(:hash) do
        { 'existing_material_budget_item_attributes' => { '1' => {
          'units' => '100.0',
          'cost_type_id' => '1',
          'comments' => 'First package',
          'budget' => '5,000.00'
        } } }
      end

      it_behaves_like 'allows params'
    end

    context 'new material budget item' do
      let(:hash) do
        { 'new_material_budget_item_attributes' => { '1' => {
          'units' => '20',
          'cost_type_id' => '2',
          'comments' => 'Macbooks',
          'budget' => '52,000.00'
        } } }
      end

      it_behaves_like 'allows params'
    end

    context 'existing labor budget item' do
      let(:hash) do
        { 'existing_labor_budget_item_attributes' => { '1' => {
          'hours' => '20.0',
          'user_id' => '1',
          'comments' => 'App Setup',
          'budget' => '2000.00'
        } } }
      end

      it_behaves_like 'allows params'
    end

    context 'new labor budget item' do
      let(:hash) do
        { 'new_labor_budget_item_attributes' => { '1' => {
          'hours' => '5.0',
          'user_id' => '2',
          'comments' => 'Overhead',
          'budget' => '400'
        } } }
      end

      it_behaves_like 'allows params'
    end
  end

  describe '#cost_type' do
    let(:attribute) { :cost_type }

    context 'name' do
      let(:hash) { { 'name' => 'name_test' } }

      it_behaves_like 'allows params'
    end

    context 'unit' do
      let(:hash) { { 'unit' => 'unit_test' } }

      it_behaves_like 'allows params'
    end

    context 'unit_plural' do
      let(:hash) { { 'unit_plural' => 'unit_plural_test' } }

      it_behaves_like 'allows params'
    end

    context 'default' do
      let(:hash) { { 'default' => 7 } }

      it_behaves_like 'allows params'
    end

    context 'new_rate_attributes' do
      let(:hash) do
        { 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' }, '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } }
      end

      it_behaves_like 'allows params'
    end

    context 'existing_rate_attributes' do
      let(:hash) do
        { 'existing_rate_attributes' => { '9' => { 'valid_from' => '2013-05-05', 'rate' => '50.0' } } }
      end

      it_behaves_like 'allows params'
    end

    context 'project_id' do
      let(:hash) { { 'project_id' => 42 } }

      it_behaves_like 'allows params' do
        let(:allowed_params) { {} }
      end
    end
  end

  describe '#user_rates' do
    let(:attribute) { :user_rates }
    let(:hash_key) { :user }

    context 'new_rate_attributes' do
      let(:hash) do
        { 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                     '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } }
      end

      it_behaves_like 'allows params'
    end

    context 'existing_rate_attributes' do
      let(:hash) do
        { 'existing_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                          '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } }
      end

      it_behaves_like 'allows params'
    end
  end

  describe '#update_work_package' do
    let(:attribute) { :update_work_package }
    let(:hash_key) { :work_package }

    context 'cost_object_id' do
      let(:hash) { { 'cost_object_id' => '1' } }

      it_behaves_like 'allows params'
    end
  end
end
