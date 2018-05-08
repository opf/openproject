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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'updating a budget', type: :feature, js: true do
  let(:project) { FactoryBot.create :project_with_types }
  let(:user) { FactoryBot.create :admin }
  let(:budget) { FactoryBot.create :cost_object, author: user, project: project }

  before do
    login_as(user)
  end

  describe 'with new cost items' do
    let(:cost_type) do
      FactoryBot.create :cost_type, name: 'Post-war', unit: 'cap', unit_plural: 'caps'
    end

    let(:budget_page) { Pages::EditBudget.new budget.id }

    before do
      project.add_member! user, FactoryBot.create(:role)

      FactoryBot.create :cost_rate, cost_type: cost_type, rate: 50.0
      FactoryBot.create :default_hourly_rate, user: user, rate: 25.0
    end

    it 'creates the cost items' do
      budget_page.visit!
      click_on 'Update'

      budget_page.add_unit_costs! 3, comment: 'Stimpak'
      budget_page.add_labor_costs! 5, user_name: user.name, comment: 'treatment'

      click_on 'Submit'
      expect(budget_page).to have_content('Successful update')

      budget_page.toggle_unit_costs!
      expect(page).to have_selector('tbody td.currency', text: '150.00 EUR')
      expect(budget_page.overall_unit_costs).to have_content '150.00 EUR'

      budget_page.toggle_labor_costs!
      expect(page).to have_selector('tbody td.currency', text: '125.00 EUR')
      expect(budget_page.labor_costs_at(1)).to have_content '125.00 EUR'
      expect(budget_page.overall_labor_costs).to have_content '125.00 EUR'
    end
  end

  describe 'with existing cost items' do
    let(:cost_type) do
      FactoryBot.create :cost_type, name: 'Post-war', unit: 'cap', unit_plural: 'caps'
    end

    let(:material_budget_item) do
      FactoryBot.create :material_budget_item, units: 3,
                                                cost_type: cost_type,
                                                cost_object: budget
    end

    let(:labor_budget_item) do
      FactoryBot.create :labor_budget_item, hours: 5,
                                             user: user,
                                             cost_object: budget
    end

    let(:budget_page) { Pages::EditBudget.new budget.id }

    before do
      project.add_member! user, FactoryBot.create(:role)

      FactoryBot.create :cost_rate, cost_type: cost_type, rate: 50.0
      FactoryBot.create :default_hourly_rate, user: user, rate: 25.0

      # trigger creation
      material_budget_item
      labor_budget_item
    end

    it 'updates the cost items' do
      budget_page.visit!
      click_on 'Update'

      budget_page.edit_unit_costs! material_budget_item.id, units: 5,
                                                     comment: 'updated num stimpaks'
      budget_page.edit_labor_costs! labor_budget_item.id, hours: 3,
                                                   user_name: user.name,
                                                   comment: 'updated treatment duration'

      click_on 'Submit'
      expect(budget_page).to have_content('Successful update')

      budget_page.toggle_unit_costs!
      expect(page).to have_selector('tbody td.currency', text: '250.00 EUR')
      expect(budget_page.unit_costs_at(1)).to have_content '250.00 EUR'
      expect(budget_page.overall_unit_costs).to have_content '250.00 EUR'

      budget_page.toggle_labor_costs!
      expect(page).to have_selector('tbody td.currency', text: '75.00 EUR')
      expect(budget_page.labor_costs_at(1)).to have_content '75.00 EUR'
      expect(budget_page.overall_labor_costs).to have_content '75.00 EUR'
    end

    it 'removes existing cost items' do
      budget_page.visit!

      click_on 'Update'

      page.find("#cost_object_existing_labor_budget_item_attributes_#{labor_budget_item.id} a.delete-budget-item").click
      click_on 'Submit'

      expect(budget_page.labor_costs_at(1)).not_to have_content '125.00 EUR'
    end
  end
end
