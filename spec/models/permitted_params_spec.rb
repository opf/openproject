#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

require File.expand_path('../../spec_helper', __FILE__)

describe PermittedParams, type: :model do
  let(:user) { FactoryGirl.build(:user) }

  describe '#cost_entry' do
    it 'should return comments' do
      params = ActionController::Parameters.new(cost_entry: { 'comments' => 'blubs' })

      expect(PermittedParams.new(params, user).cost_entry).to eq({ 'comments' => 'blubs' })
    end

    it 'should return units' do
      params = ActionController::Parameters.new(cost_entry: { 'units' => '5.0' })

      expect(PermittedParams.new(params, user).cost_entry).to eq({ 'units' => '5.0' })
    end

    it 'should return overridden_costs' do
      params = ActionController::Parameters.new(cost_entry: { 'overridden_costs' => '5.0' })

      expect(PermittedParams.new(params, user).cost_entry).to eq({ 'overridden_costs' => '5.0' })
    end

    it 'should return spent_on' do
      params = ActionController::Parameters.new(cost_entry: { 'spent_on' => Date.today.to_s })

      expect(PermittedParams.new(params, user).cost_entry).to eq({ 'spent_on' => Date.today.to_s })
    end

    it 'should not return project_id' do
      params = ActionController::Parameters.new(cost_entry: { 'project_id' => 42 })

      expect(PermittedParams.new(params, user).cost_entry).to eq({})
    end
  end

  describe '#cost_object' do
    it 'should return comments' do
      params = ActionController::Parameters.new(cost_object: { 'subject' => 'subject_test' })

      expect(PermittedParams.new(params, user).cost_object).to eq({ 'subject' => 'subject_test' })
    end

    it 'should return description' do
      params = ActionController::Parameters.new(cost_object: { 'description' => 'description_test' })

      expect(PermittedParams.new(params, user).cost_object).to eq({ 'description' => 'description_test' })
    end

    it 'should return fixed_date' do
      params = ActionController::Parameters.new(cost_object: { 'fixed_date' => '2013-05-06' })

      expect(PermittedParams.new(params, user).cost_object).to eq({ 'fixed_date' => '2013-05-06' })
    end

    it 'should not return project_id' do
      params = ActionController::Parameters.new(cost_object: { 'project_id' => 42 })

      expect(PermittedParams.new(params, user).cost_object).to eq({})
    end

    context 'with budget item params' do
      let(:params) { ActionController::Parameters.new(cost_object: budget_item_params) }
      subject { PermittedParams.new(params, user).cost_object }

      context 'of an existing material budget item' do
        let(:budget_item_params) do
          { 'existing_material_budget_item_attributes' => { '1' => {
            'units' => '100.0',
            'cost_type_id' => '1',
            'comments' => 'First package',
            'budget' => '5,000.00'
          }
                                                        } }
        end

        it { is_expected.to eq(budget_item_params) }
      end

      context 'of a new material budget item' do
        let(:budget_item_params) do
          { 'new_material_budget_item_attributes' => { '1' => {
            'units' => '20',
            'cost_type_id' => '2',
            'comments' => 'Macbooks',
            'budget' => '52,000.00'
          } } }
        end

        it { is_expected.to eq(budget_item_params) }
      end

      context 'of an existing labor budget item' do
        let(:budget_item_params) do
          { 'existing_labor_budget_item_attributes' => { '1' => {
            'hours' => '20.0',
            'user_id' => '1',
            'comments' => 'App Setup',
            'budget' => '2000.00'
          } } }
        end

        it { is_expected.to eq(budget_item_params) }
      end

      context 'of a new labor budget item' do
        let(:budget_item_params) do
          { 'new_labor_budget_item_attributes' => { '1' => {
            'hours' => '5.0',
            'user_id' => '2',
            'comments' => 'Overhead',
            'budget' => '400'
          } } }
        end

        it { is_expected.to eq(budget_item_params) }
      end
    end
  end

  describe '#cost_type' do
    it 'should return name' do
      params = ActionController::Parameters.new(cost_type: { 'name' => 'name_test' })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'name' => 'name_test' })
    end

    it 'should return unit' do
      params = ActionController::Parameters.new(cost_type: { 'unit' => 'unit_test' })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'unit' => 'unit_test' })
    end

    it 'should return unit_plural' do
      params = ActionController::Parameters.new(cost_type: { 'unit_plural' => 'unit_plural_test' })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'unit_plural' => 'unit_plural_test' })
    end

    it 'should return default' do
      params = ActionController::Parameters.new(cost_type: { 'default' => 7 })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'default' => 7 })
    end

    it 'should return new_rate_attributes' do
      params = ActionController::Parameters.new(cost_type: { 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' }, '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' }, '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })
    end

    it 'should return existing_rate_attributes' do
      params = ActionController::Parameters.new(cost_type: { 'existing_rate_attributes' => { '9' => { 'valid_from' => '2013-05-05', 'rate' => '50.0' } } })

      expect(PermittedParams.new(params, user).cost_type).to eq({ 'existing_rate_attributes' => { '9' => { 'valid_from' => '2013-05-05', 'rate' => '50.0' } } })
    end

    it 'should not return project_id' do
      params = ActionController::Parameters.new(cost_type: { 'project_id' => 42 })

      expect(PermittedParams.new(params, user).cost_type).to eq({})
    end
  end

  describe '#user_rates' do
    it 'should return new_rate_attributes' do
      params = ActionController::Parameters.new(user: { 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                                                                   '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })

      expect(PermittedParams.new(params, user).user_rates).to eq({ 'new_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                                                                              '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })
    end

    it 'should return existing_rate_attributes' do
      params = ActionController::Parameters.new(user: { 'existing_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                                                                        '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })

      expect(PermittedParams.new(params, user).user_rates).to eq({ 'existing_rate_attributes' => { '0' => { 'valid_from' => '2013-05-08', 'rate' => '5002' },
                                                                                                   '1' => { 'valid_from' => '2013-05-10', 'rate' => '5004' } } })
    end
  end

  describe '#update_work_package' do
    it 'should permit cost_object_id' do
      hash = { 'cost_object_id' => '1' }

      params = ActionController::Parameters.new(work_package: hash)

      expect(PermittedParams.new(params, user).update_work_package).to eq(hash)
    end
  end
end
