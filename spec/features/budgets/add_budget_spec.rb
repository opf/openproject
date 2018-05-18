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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe 'adding a new budget', type: :feature, js: true do
  let(:project) { FactoryGirl.create :project_with_types }
  let(:user) { FactoryGirl.create :admin }

  before do
    allow(User).to receive(:current).and_return user
  end

  it 'shows link to create a new budget' do
    visit projects_cost_objects_path(project)

    click_on("Add budget")

    expect(page).to have_content "New budget"
    expect(page).to have_content "Description"
    expect(page).to have_content "Subject"
  end

  it 'create the budget' do
    visit new_projects_cost_object_path(project)

    fill_in("Subject", with: 'My subject')

    click_on "Create"

    expect(page).to have_content "Successful creation"
    expect(page).to have_content "My subject"
  end

  context 'with cost items' do
    let(:cost_type) do
      FactoryGirl.create :cost_type, name: 'Post-war', unit: 'cap', unit_plural: 'caps'
    end

    let(:new_budget_page) { Pages::NewBudget.new project.identifier }

    before do
      project.add_member! user, FactoryGirl.create(:role)

      FactoryGirl.create :cost_rate, cost_type: cost_type, rate: 50.0
      FactoryGirl.create :default_hourly_rate, user: user, rate: 25.0
    end

    it 'creates the budget including the given cost items' do
      new_budget_page.visit!

      fill_in 'Subject', with: 'First Aid'

      new_budget_page.add_unit_costs! 3, comment: 'RadAway'
      new_budget_page.add_unit_costs! 2, comment: 'Rad-X'

      new_budget_page.add_labor_costs! 5, user_name: user.name, comment: 'treatment'
      new_budget_page.add_labor_costs! 2, user_name: user.name, comment: 'attendance'

      click_on 'Create'
      expect(page).to have_content('Successful creation')

      new_budget_page.toggle_unit_costs!
      expect(page).to have_selector('td.currency', text: '150.00 EUR')
      expect(new_budget_page.unit_costs_at(1)).to have_content '150.00 EUR'
      expect(new_budget_page.unit_costs_at(2)).to have_content '100.00 EUR'
      expect(new_budget_page.overall_unit_costs).to have_content '250.00 EUR'

      new_budget_page.toggle_labor_costs!
      expect(page).to have_selector('td.currency', text: '125.00 EUR')
      expect(new_budget_page.labor_costs_at(1)).to have_content '125.00 EUR'
      expect(new_budget_page.labor_costs_at(2)).to have_content '50.00 EUR'
      expect(new_budget_page.overall_labor_costs).to have_content '175.00 EUR'
    end
  end
end
