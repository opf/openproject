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

require 'spec_helper'

describe 'deleting a cost type', type: :feature, js: true do
  let!(:user) { FactoryBot.create :admin }
  let!(:cost_type) {
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate, cost_type: type, rate: 1.00
    type
  }

  before do
    login_as user
  end

  it 'can delete the cost type' do
    visit cost_types_path

    within ("#delete_cost_type_#{cost_type.id}") do
      scroll_to_and_click(find('button.submit_cost_type'))
    end

    # Expect no results if not locked
    expect_angular_frontend_initialized
    expect(page).to have_selector '.generic-table--no-results-container', wait: 10

    # Show locked
    find('#include_deleted').set true
    click_on 'Apply'

    # Expect no results if not locked
    expect(page).to have_text I18n.t(:label_locked_cost_types)

    expect(page).to have_selector('.restore_cost_type')
    expect(page).to have_selector('.cost-types--list-deleted td', text: 'Translations')
  end
end
