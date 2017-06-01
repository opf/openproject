#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

RSpec.feature 'Work package index sums', js: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:project) {
    FactoryGirl.create(:project, name: 'project1', identifier: 'project1')
  }

  let!(:work_package_1) {
    FactoryGirl.create(:work_package, project: project, estimated_hours: 10)
  }
  let!(:work_package_2) {
    FactoryGirl.create(:work_package, project: project, estimated_hours: 15)
  }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(admin)

    visit project_work_packages_path(project)
    expect(current_path).to eq('/projects/project1/work_packages')
  end

  scenario 'calculates summs correctly' do
    expect(page).to have_content('Work packages')

    within('.work-packages-list-view--container') do
      expect(page).to have_content(work_package_1.subject)
      expect(page).to have_content(work_package_2.subject)
    end

    # name of the settings dropdown menu
    dropdown_id = 'settings'

    # Trigger action from action menu dropdown
    find("button[has-dropdown-menu][target=#{dropdown_id}DropdownMenu]").click
    find("##{dropdown_id}Dropdown").click_link 'Columns'

    within('.ng-modal-inner') do
      find('input.select2-input').click

      s2_result = find('ul.select2-result-single li', text: 'Estimated time')
      s2_result.click

      click_on 'Apply'
    end

    # Trigger action from action menu dropdown
    find("button[has-dropdown-menu][target=#{dropdown_id}DropdownMenu]").click
    find("##{dropdown_id}Dropdown").click_link 'Display sums'

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
