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

require 'spec_helper'

describe 'creating a cost type', type: :feature, js: true do
  let!(:user) { FactoryBot.create :admin }
  let!(:cost_type) do
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate, cost_type: type, rate: 1.00
    type
  end

  before do
    login_as user
  end

  it 'can create a cost type' do
    visit "/cost_types/new"

    fill_in 'cost_type_name', with: 'Test day rate'
    fill_in 'cost_type_unit', with: 'dayUnit'
    fill_in 'cost_type_unit_plural', with: 'dayUnitPlural'
    fill_in 'cost_type_new_rate_attributes_0_rate', with: '1,000.25'

    sleep 1

    scroll_to_and_click(find('button.-with-icon.icon-checkmark'))

    expect_angular_frontend_initialized
    expect(page).to have_selector '.generic-table', wait: 10

    cost_type_row = find('tr', text: 'Test day rate')

    expect(cost_type_row).to have_selector('td a', text: 'Test day rate')
    expect(cost_type_row).to have_selector('td', text: 'dayUnit')
    expect(cost_type_row).to have_selector('td', text: 'dayUnitPlural')
    expect(cost_type_row).to have_selector('td.currency', text: '1,000.25')

    cost_type = CostType.last
    expect(cost_type.name).to eq 'Test day rate'
    cost_rate = cost_type.rates.last
    expect(cost_rate.rate).to eq 1000.25
  end

  context 'with german locale' do
    let(:user) { FactoryBot.create(:admin, language: :de) }

    it 'creates the entry with german number separators' do
      visit "/cost_types/new"

      fill_in 'cost_type_name', with: 'Test day rate'
      fill_in 'cost_type_unit', with: 'dayUnit'
      fill_in 'cost_type_unit_plural', with: 'dayUnitPlural'
      fill_in 'cost_type_new_rate_attributes_0_rate', with: '1.000,25'

      sleep 1

      scroll_to_and_click(find('button.-with-icon.icon-checkmark'))

      expect_angular_frontend_initialized
      expect(page).to have_selector '.generic-table', wait: 10

      cost_type_row = find('tr', text: 'Test day rate')

      expect(cost_type_row).to have_selector('td a', text: 'Test day rate')
      expect(cost_type_row).to have_selector('td', text: 'dayUnit')
      expect(cost_type_row).to have_selector('td', text: 'dayUnitPlural')
      expect(cost_type_row).to have_selector('td.currency', text: '1.000,25')

      cost_type = CostType.last
      expect(cost_type.name).to eq 'Test day rate'
      cost_rate = cost_type.rates.last
      expect(cost_rate.rate).to eq 1000.25
    end
  end
end
