#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe 'Copying a budget', type: :feature, js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[budgets costs] }
  let(:current_user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i(view_budgets edit_budgets view_hourly_rates view_cost_rates)
  end
  let(:original_author) { FactoryBot.create :user }
  let(:budget_subject) { "A budget subject" }
  let(:budget_description) { "A budget description" }
  let!(:budget) do
    FactoryBot.create :budget,
                      subject: budget_subject,
                      description: budget_description,
                      author: original_author,
                      project: project
  end
  let!(:cost_type) do
    FactoryBot.create :cost_type, name: 'Post-war', unit: 'cap', unit_plural: 'caps'
  end
  let!(:cost_type_rate) { FactoryBot.create :cost_rate, cost_type: cost_type, rate: 50.0 }
  let!(:default_hourly_rate) { FactoryBot.create :default_hourly_rate, user: original_author, rate: 25.0 }
  let!(:material_budget_item) do
    FactoryBot.create :material_budget_item,
                      units: 3,
                      cost_type: cost_type,
                      budget: budget
  end
  let!(:overwritten_material_budget_item) do
    FactoryBot.create :material_budget_item,
                      units: 10,
                      cost_type: cost_type,
                      budget: budget,
                      amount: 600000.00
  end

  let!(:labor_budget_item) do
    FactoryBot.create :labor_budget_item,
                      hours: 5,
                      user: original_author,
                      budget: budget
  end
  let(:budget_page) { Pages::EditBudget.new budget.id }

  before do
    login_as(current_user)
  end

  it 'copies all the items of the budget under the name of the copying user' do
    budget_page.visit!

    budget_page.click_copy

    budget_page.expect_subject(budget_subject)

    budget_page.expect_planned_costs!(type: :labor, row: 1, expected: '125.00 EUR')
    budget_page.expect_planned_costs!(type: :material, row: 1, expected: '150.00 EUR')
    budget_page.expect_planned_costs!(type: :material, row: 2, expected: '600,000.00 EUR')

    click_button 'Create'

    budget_page.expect_notification message: 'Successful creation.'

    expect(page)
      .to have_selector('.author', text: current_user.name)
  end
end
