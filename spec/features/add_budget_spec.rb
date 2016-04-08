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

    before do
      project.add_member! user, FactoryGirl.create(:role)

      FactoryGirl.create :cost_rate, cost_type: cost_type, rate: 50.0
      FactoryGirl.create :default_hourly_rate, user: user, rate: 25.0
    end

    it 'creates the budget including the given cost items' do
      visit new_projects_cost_object_path(project)

      fill_in 'Subject', with: 'First Aid'

      mat_id = 'cost_object_new_material_budget_item_attributes'
      fill_in "#{mat_id}_0_units", with: 3
      fill_in "#{mat_id}_0_comments", with: 'RadAway'

      within('#material_budget_items_fieldset') do
        find('a', text: 'Add planned costs').native.send_keys(:return)
      end

      fill_in "#{mat_id}_1_units", with: 2
      fill_in "#{mat_id}_1_comments", with: 'Rad-X'

      lab_id = 'cost_object_new_labor_budget_item_attributes'
      fill_in "#{lab_id}_0_hours", with: 5
      select user.name, from: "#{lab_id}_0_user_id"
      fill_in "#{lab_id}_0_comments", with: 'treatment'

      within('#labor_budget_items_fieldset') do
        find('a', text: 'Add planned costs').native.send_keys(:return)
      end

      fill_in "#{lab_id}_1_hours", with: 2
      select user.name, from: "#{lab_id}_1_user_id"
      fill_in "#{lab_id}_1_comments", with: 'attendance'

      click_on 'Create'

      units = find('fieldset', text: 'UNITS')
      units.click

      expect(page).to have_content('Successful creation')

      div = find('h4', text: 'Planned unit costs').find(:xpath, '..')
      currency = div.first('tbody td.currency')
      expect(currency).to have_content('150.00 EUR')
      expect(div.all('tbody td.currency').last).to have_content('100.00 EUR')
      expect(div.first('tfoot td.currency')).to have_content('250.00 EUR')

      find('fieldset', text: 'LABOR').click

      labor = find('h4', text: 'Planned labor costs').find(:xpath, '..')
      expect(labor.first('tbody td.currency')).to have_content('125.00 EUR')
      expect(labor.all('tbody td.currency').last).to have_content('50.00 EUR')
      expect(labor.first('tfoot td.currency')).to have_content('175.00 EUR')
    end
  end
end
