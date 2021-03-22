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

RSpec.feature 'Work package index sums', js: true do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_own_hourly_rate
                                                  view_work_packages
                                                  edit_work_packages
                                                  view_time_entries
                                                  view_cost_entries
                                                  view_cost_rates
                                                  log_costs]
  end
  let(:project) do
    FactoryBot.create(:project, name: 'project1', identifier: 'project1')
  end
  let(:type) { FactoryBot.create(:type) }
  let!(:int_cf) do
    FactoryBot.create(:int_wp_custom_field).tap do |cf|
      project.work_package_custom_fields << cf
      type.custom_fields << cf
    end
  end
  let!(:float_cf) do
    FactoryBot.create(:float_wp_custom_field).tap do |cf|
      project.work_package_custom_fields << cf
      type.custom_fields << cf
    end
  end
  let!(:work_package_1) do
    FactoryBot.create(:work_package, project: project, type: type, estimated_hours: 10).tap do |wp|
      wp.custom_field_values = { int_cf.id => 5, float_cf.id => 5.5 }
      wp.save!
    end
  end
  let!(:work_package_2) do
    FactoryBot.create(:work_package, project: project, type: type, estimated_hours: 15).tap do |wp|
      wp.custom_field_values = { int_cf.id => 7, float_cf.id => 7.7 }
      wp.save!
    end
  end
  let!(:hourly_rate) do
    FactoryBot.create :default_hourly_rate,
                      user: user,
                      rate: 10.00
  end
  let!(:time_entry) do
    FactoryBot.create :time_entry,
                      user: user,
                      work_package: work_package_1,
                      project: project,
                      hours: 1.50
  end
  let(:cost_type) do
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate,
                      cost_type: type,
                      rate: 3.00
    type
  end
  let!(:cost_entry) do
    FactoryBot.create :cost_entry,
                      work_package: work_package_1,
                      project: project,
                      units: 2.50,
                      cost_type: cost_type,
                      user: user
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }

  before do
    login_as(user)

    visit project_work_packages_path(project)
    expect(current_path).to eq('/projects/project1/work_packages')
  end

  scenario 'calculates sums correctly' do
    wp_table.expect_work_package_listed work_package_1, work_package_2

    # Add estimated time column
    columns.add 'Estimated time'
    # Add int cf column
    columns.add int_cf.name
    # Add float cf column
    columns.add float_cf.name
    # Add overall costs column
    columns.add 'Overall costs', finicky: true
    # Add unit costs column
    columns.add 'Unit costs', finicky: true
    # Add labor costs column
    columns.add 'Labor costs', finicky: true

    # Trigger action from action menu dropdown
    modal.set_display_sums enable: true

    wp_table.expect_work_package_listed work_package_1, work_package_2

    # Expect the total sums row
    expect(page).to have_selector('.wp-table--sums-row', count: 1)

    expect(page).to have_selector('.wp-table--sum-container', text: 'Total sum')
    expect(page).to have_selector('.wp-table--sum-container', text: '25')
    expect(page).to have_selector('.wp-table--sum-container', text: '12')
    expect(page).to have_selector('.wp-table--sum-container', text: '13.2')
    # Unit costs
    expect(page).to have_selector('.wp-table--sum-container', text: '7.50')
    # Overall costs
    expect(page).to have_selector('.wp-table--sum-container', text: '22.50')
    # Labor costs
    expect(page).to have_selector('.wp-table--sum-container', text: '15.00')

    # Update the sum
    edit_field = wp_table.edit_field(work_package_1, :estimatedTime)
    edit_field.update '20'

    expect(page).to have_selector('.wp-table--sum-container', text: 'Total sum')
    expect(page).to have_selector('.wp-table--sum-container', text: '35')
    expect(page).to have_selector('.wp-table--sum-container', text: '12')
    expect(page).to have_selector('.wp-table--sum-container', text: '13.2')
    # Unit costs
    expect(page).to have_selector('.wp-table--sum-container', text: '7.50')
    # Overall costs
    expect(page).to have_selector('.wp-table--sum-container', text: '22.50')
    # Labor costs
    expect(page).to have_selector('.wp-table--sum-container', text: '15.00')

    # Enable groups
    group_by.enable_via_menu 'Status'

    # Expect to have three sums rows now
    expect(page).to have_selector('.wp-table--sums-row', count: 3)

    # First status row
    expect(page).to have_selector('.wp-table--sum-container', text: '20 h')
    expect(page).to have_selector(".wp-table--sum-container.customField#{int_cf.id}", text: '5')
    expect(page).to have_selector(".wp-table--sum-container.customField#{float_cf.id}", text: '5.5')
    # Unit costs
    expect(page).to have_selector('.wp-table--sum-container.materialCosts', text: '7.50')
    # Overall costs
    expect(page).to have_selector('.wp-table--sum-container.overallCosts', text: '22.50')
    # Labor costs
    expect(page).to have_selector('.wp-table--sum-container.laborCosts', text: '15.00')

    # Second status row
    expect(page).to have_selector('.wp-table--sum-container', text: '15 h')
    expect(page).to have_selector(".wp-table--sum-container.customField#{int_cf.id}", text: '7')
    expect(page).to have_selector(".wp-table--sum-container.customField#{float_cf.id}", text: '7.7')

    # Total sums row is unchanged
    expect(page).to have_selector('tbody .wp-table--sum-container', text: '35')
    expect(page).to have_selector("tbody .wp-table--sum-container.customField#{int_cf.id}", text: '12')
    expect(page).to have_selector("tbody .wp-table--sum-container.customField#{float_cf.id}", text: '13.2')
    # Unit costs
    expect(page).to have_selector('tbody .wp-table--sum-container.materialCosts', text: '7.50')
    # Overall costs
    expect(page).to have_selector('tbody .wp-table--sum-container.overallCosts', text: '22.50')
    # Labor costs
    expect(page).to have_selector('tbody .wp-table--sum-container.laborCosts', text: '15.00')

    # Collapsing groups will also hide the sums row
    page.find('.expander.icon-minus2', match: :first).click
    sleep 1
    page.find('.expander.icon-minus2', match: :first).click

    # Expect to have only the final sums
    expect(page).to have_selector('tbody .wp-table--sums-row', count: 1)
  end
end
