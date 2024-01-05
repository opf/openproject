#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

RSpec.describe 'Work package index sums', :js do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_own_hourly_rate
                                                    view_work_packages
                                                    edit_work_packages
                                                    view_time_entries
                                                    view_cost_entries
                                                    view_cost_rates
                                                    log_costs] })
  end
  let(:project) do
    create(:project,
           name: 'project1',
           identifier: 'project1')
  end
  let(:type) { create(:type) }
  let!(:int_cf) do
    create(:integer_wp_custom_field) do |cf|
      project.work_package_custom_fields << cf
      type.custom_fields << cf
    end
  end
  let!(:float_cf) do
    create(:float_wp_custom_field) do |cf|
      project.work_package_custom_fields << cf
      type.custom_fields << cf
    end
  end
  let!(:work_package1) do
    create(:work_package,
           project:, type:,
           estimated_hours: 10,
           remaining_hours: 5) do |wp|
      wp.custom_field_values = { int_cf.id => 5, float_cf.id => 5.5 }
      wp.save!
    end
  end
  let!(:work_package2) do
    create(:work_package,
           project:,
           type:,
           estimated_hours: 15,
           remaining_hours: 7.5) do |wp|
      wp.custom_field_values = { int_cf.id => 7, float_cf.id => 7.7 }
      wp.save!
    end
  end
  let!(:hourly_rate) do
    create(:default_hourly_rate,
           user:,
           rate: 10.00)
  end
  let!(:time_entry) do
    create(:time_entry,
           user:,
           work_package: work_package1,
           project:,
           hours: 1.50)
  end
  let(:cost_type) do
    type = create(:cost_type, name: 'Translations')
    create(:cost_rate,
           cost_type: type,
           rate: 3.00)
    type
  end
  let!(:cost_entry) do
    create(:cost_entry,
           work_package: work_package1,
           project:,
           units: 2.50,
           cost_type:,
           user:)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  current_user { user }

  it 'calculates sums correctly' do
    visit project_work_packages_path(project)
    wp_table.expect_work_package_listed work_package1, work_package2

    # Add work column
    columns.add 'Work'
    # Add remaining work column
    columns.add 'Remaining work'
    # Add int cf column
    columns.add int_cf.name
    # Add float cf column
    columns.add float_cf.name
    # Add overall costs column
    columns.add 'Overall costs'
    # Add unit costs column
    columns.add 'Unit costs'
    # Add labor costs column
    columns.add 'Labor costs'

    # Trigger action from action menu dropdown
    modal.set_display_sums enable: true

    wp_table.expect_work_package_listed work_package1, work_package2

    # Expect the total sums row
    within(:row, "Total sum") do |row|
      expect(row).to have_css('.estimatedTime', text: '25 h')
      expect(row).to have_css('.remainingTime', text: '12.5 h')
      expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: '12')
      expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: '13.2')
      expect(row).to have_css('.overallCosts', text: '22.50 EUR')
      expect(row).to have_css('.materialCosts', text: '7.50 EUR') # Unit costs
      expect(row).to have_css('.laborCosts', text: '15.00 EUR')
    end

    # Update the sum
    wp_table.edit_field(work_package1, :estimatedTime)
            .update '20'
    wp_table.edit_field(work_package1, :remainingTime)
            .update '12'

    within(:row, "Total sum") do |row|
      expect(row).to have_css('.estimatedTime', text: '35 h')
      expect(row).to have_css('.remainingTime', text: '19.5 h')
      expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: '12')
      expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: '13.2')
      expect(row).to have_css('.overallCosts', text: '22.50 EUR')
      expect(row).to have_css('.materialCosts', text: '7.50 EUR') # Unit costs
      expect(row).to have_css('.laborCosts', text: '15.00 EUR')
    end

    # Enable groups
    group_by.enable_via_menu 'Status'

    # Expect to have three sums rows now
    expect(page).to have_row('Sum', count: 2)
    expect(page).to have_row('Total sum', count: 1)

    first_sum_row, second_sum_row = *find_all(:row, 'Sum')
    # First status row
    expect(first_sum_row).to have_css('.estimatedTime', text: '20 h')
    expect(first_sum_row).to have_css('.remainingTime', text: '12 h')
    expect(first_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: '5')
    expect(first_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: '5.5')
    expect(first_sum_row).to have_css('.overallCosts', text: '22.50 EUR')
    expect(first_sum_row).to have_css('.materialCosts', text: '7.50 EUR') # Unit costs
    expect(first_sum_row).to have_css('.laborCosts', text: '15.00 EUR')

    # Second status row
    expect(second_sum_row).to have_css('.estimatedTime', text: '15 h')
    expect(second_sum_row).to have_css('.remainingTime', text: '7.5 h')
    expect(second_sum_row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: '7')
    expect(second_sum_row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: '7.7')
    expect(second_sum_row).to have_css('.overallCosts', text: '', exact_text: true)
    expect(second_sum_row).to have_css('.materialCosts', text: '', exact_text: true) # Unit costs
    expect(second_sum_row).to have_css('.laborCosts', text: '', exact_text: true)

    # Total sums row is unchanged
    within(:row, "Total sum") do |row|
      expect(row).to have_css('.estimatedTime', text: '35 h')
      expect(row).to have_css('.remainingTime', text: '19.5 h')
      expect(row).to have_css(".#{int_cf.attribute_name(:camel_case)}", text: '12')
      expect(row).to have_css(".#{float_cf.attribute_name(:camel_case)}", text: '13.2')
      expect(row).to have_css('.overallCosts', text: '22.50 EUR')
      expect(row).to have_css('.materialCosts', text: '7.50 EUR') # Unit costs
      expect(row).to have_css('.laborCosts', text: '15.00 EUR')
    end

    # Collapsing groups will also hide the sums row
    page.find('.expander.icon-minus2', match: :first).click
    sleep 1
    page.find('.expander.icon-minus2', match: :first).click

    # Expect to have only the final sums
    expect(page).not_to have_row('Sum')
    expect(page).to have_row('Total sum')
  end
end
