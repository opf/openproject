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

require 'spec_helper'

RSpec.feature 'Work package index sums', js: true do
  using_shared_fixtures :admin

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

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }

  before do
    login_as(admin)

    allow(Setting)
      .to receive(:work_package_list_summable_columns)
      .and_return(%W(estimated_hours cf_#{int_cf.id} cf_#{float_cf.id}))

    visit project_work_packages_path(project)
    expect(current_path).to eq('/projects/project1/work_packages')
  end

  scenario 'calculates summs correctly' do
    wp_table.expect_work_package_listed work_package_1, work_package_2

    # Add estimated time column
    columns.add 'Estimated time'
    # Add int cf column
    columns.add int_cf.name
    # Add float cf column
    columns.add float_cf.name

    # Trigger action from action menu dropdown
    modal.set_display_sums enable: true

    wp_table.expect_work_package_listed work_package_1, work_package_2

    expect(page).to have_selector('.wp-table--sum-container', text: 'Sum')
    expect(page).to have_selector('.wp-table--sum-container', text: '25')
    expect(page).to have_selector('.wp-table--sum-container', text: '12')
    expect(page).to have_selector('.wp-table--sum-container', text: '13.2')

    # Update the sum
    edit_field = wp_table.edit_field(work_package_1, :estimatedTime)
    edit_field.update '20'

    expect(page).to have_selector('.wp-table--sum-container', text: 'Sum')
    expect(page).to have_selector('.wp-table--sum-container', text: '35')
    expect(page).to have_selector('.wp-table--sum-container', text: '12')
    expect(page).to have_selector('.wp-table--sum-container', text: '13.2')
  end
end
