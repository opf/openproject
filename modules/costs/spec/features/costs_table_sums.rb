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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Work Package table cost sums', type: :feature, js: true do
  let(:project) { work_package.project }
  let(:user) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: role }
  let(:role) { FactoryBot.create :role, permissions: [:view_own_hourly_rate,
                                                       :view_work_packages,
                                                       :view_work_packages,
                                                       :view_own_time_entries,
                                                       :view_own_cost_entries,
                                                       :view_cost_rates,
                                                       :log_costs] }
  let(:work_package) {FactoryBot.create :work_package }
  let(:hourly_rate) { FactoryBot.create :default_hourly_rate, user: user,
                                                               rate: 1.00 }
  let!(:time_entry) { FactoryBot.create :time_entry, user: user,
                                                     work_package: work_package,
                                                     project: project,
                                                     hours: 1.50 }
  let(:cost_type) {
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate, cost_type: type,
                                   rate: 1.00
    type
  }
  let!(:cost_entry) { FactoryBot.create :cost_entry, work_package: work_package,
                                                     project: project,
                                                     units: 2.50,
                                                     cost_type: cost_type,
                                                     user: user }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = %w(subject overall_costs material_costs overall_costs)

    query.save!
    query
  end

  before do
    login_as(user)
    allow(Setting).to receive(:work_package_list_summable_columns).and_return(summable)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(work_package)

    # Trigger action from action menu dropdown
    wp_table.click_setting_item 'Display sums'
    expect(page).to have_selector('tr.sum.group.all')
  end

  context 'when summing enabled' do
    let(:summable) { %w(overall_costs labor_costs material_costs) }

    it 'shows the sums' do
      within('tr.sum.group.all') do
        expect(page).to have_selector('.inline-edit--display-field', text: '2.50 EUR', count: 3)
        expect(page).to have_selector('.inline-edit--display-field', text: '-', count: 1)
      end
    end
  end
  context 'when summing disabled' do
    let(:summable) { [] }

    it 'does not show the sums' do
      within('tr.sum.group.all') do
        expect(page).to have_selector('.inline-edit--display-field', text: '-', count: 4)
      end
    end
  end
end
