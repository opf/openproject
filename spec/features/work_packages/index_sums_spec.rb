#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

  let(:admin) { FactoryBot.create(:admin) }
  let(:project) {
    FactoryBot.create(:project, name: 'project1', identifier: 'project1')
  }

  let!(:work_package_1) {
    FactoryBot.create(:work_package, project: project, estimated_hours: 10)
  }
  let!(:work_package_2) {
    FactoryBot.create(:work_package, project: project, estimated_hours: 15)
  }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }

  before do
    login_as(admin)

    visit project_work_packages_path(project)
    expect(current_path).to eq('/projects/project1/work_packages')
  end

  scenario 'calculates summs correctly' do
    wp_table.expect_work_package_listed work_package_1, work_package_2

    # Add estimated time column
    columns.add 'Estimated time'

    # Trigger action from action menu dropdown
    modal.set_display_sums enable: true

    wp_table.expect_work_package_listed work_package_1, work_package_2

    within('.sum.group.all') do
      expect(page).to have_content('Sum for all work packages')
      expect(page).to have_content('25')
    end

    # Update the sum
    edit_field = wp_table.edit_field(work_package_1, :estimatedTime)
    edit_field.update '20'

    within('.sum.group.all') do
      expect(page).to have_content('Sum for all work packages')
      expect(page).to have_content('35')
    end
  end
end
