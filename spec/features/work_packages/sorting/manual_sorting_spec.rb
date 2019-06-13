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
require 'features/work_packages/work_packages_page'

# ToDo:
# Remove skip once finished
describe 'Manual sorting of WP table', type: :feature, js: true, skip: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:work_package_1) do
    FactoryBot.create(:work_package, project: project, created_at: Time.now)
  end
  let(:work_package_2) do
    FactoryBot.create(:work_package, project: project, created_at: Time.now - 1.minutes)
  end
  let(:work_package_3) do
    FactoryBot.create(:work_package, project: project, created_at: Time.now - 2.minutes)
  end
  let(:work_package_4) do
    FactoryBot.create(:work_package, project: project, created_at: Time.now - 3.minutes)
  end

  let(:sort_by) { ::Components::WorkPackages::SortBy.new }
  let(:dialog) { ::Components::PasswordConfirmationDialog.new }

  before do
    login_as(user)

    work_package_1
    work_package_2
    work_package_3
    work_package_4

    wp_table.visit!
  end

  include_context 'ui-select helpers'
  include_context 'work package table helpers'

  it 'can sort table rows via DragNDrop' do
    # ToDo
  end

  it 'saves the changed order in a previously saved query' do
    # ToDo
  end

  it 'does not loose the current order when switching to manual sorting' do
    # Sort by creation date
    sort_by.open_modal
    sort_by.update_nth_criteria(0, 'Created on')
    sort_by.apply_changes
    expect_work_packages_to_be_in_order([work_package_4, work_package_3, work_package_2, work_package_1])

    # Enable manual sorting
    sort_by.open_modal
    sort_by.update_sorting_mode 'manual'
    sort_by.apply_changes

    # Expect same order
    expect_work_packages_to_be_in_order([work_package_4, work_package_3, work_package_2, work_package_1])
  end

  it 'shows a warning when switching from manual to automatic sorting' do
    # Sort manually
    # ToDo: function does not work yet
    sort_by.move_WP_manually from: 1, to: 3
    expect_work_packages_to_be_in_order([work_package_1, work_package_3, work_package_4, work_package_2])

    # Try to sort by creation date
    sort_by.sort_via_header name: 'subject', selector: 'name'

    # Shows a warning
    dialog.expect_open
    dialog.confirm
    expect_work_packages_to_be_in_order([work_package_4, work_package_3, work_package_2, work_package_1])
  end

end
