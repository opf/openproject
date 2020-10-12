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
require 'features/work_packages/work_packages_page'

describe 'Filter updates pagination', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages])
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  let(:project) { FactoryBot.create(:project) }
  let(:work_package_1) { FactoryBot.create(:work_package, project: project, assigned_to: user) }
  let(:work_package_2) { FactoryBot.create(:work_package, project: project) }

  before do
    allow(Setting).to receive(:per_page_options).and_return '1'

    work_package_1
    work_package_2

    login_as user
    wp_table.visit!
  end

  it 'will reset page to 1 if changing filter' do
    wp_table.expect_work_package_listed work_package_1
    wp_table.ensure_work_package_not_listed! work_package_2

    # Expect pagination to be correct
    expect(page).to have_selector('.pagination--item.-current', text: '1')

    # Go to second page
    within('.pagination--pages') do
      find('.pagination--item a', text: '2').click
    end

    wp_table.expect_work_package_listed work_package_2
    wp_table.ensure_work_package_not_listed! work_package_1

    # Expect pagination to be correct
    expect(page).to have_selector('.pagination--item.-current', text: '2')

    # Change filter to assigned to
    filters.expect_filter_count 1
    filters.open
    filters.add_filter_by 'Assignee', 'is', user.name
    filters.expect_filter_count 2

    wp_table.expect_work_package_listed work_package_1
    wp_table.ensure_work_package_not_listed! work_package_2

    # Expect pagination to be back to 1
    expect(page).to have_selector('.pagination--range', text: '1 - 1/1')
  end
end
