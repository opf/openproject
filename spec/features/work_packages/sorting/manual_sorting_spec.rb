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
describe 'Manual sorting of WP table', type: :feature, js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:work_package_1) do
    FactoryBot.create(:work_package, subject: 'WP1', project: project, created_at: Time.now)
  end
  let(:work_package_2) do
    FactoryBot.create(:work_package, subject: 'WP2', project: project, created_at: Time.now - 1.minutes)
  end
  let(:work_package_3) do
    FactoryBot.create(:work_package, subject: 'WP3', project: project, created_at: Time.now - 2.minutes)
  end
  let(:work_package_4) do
    FactoryBot.create(:work_package, subject: 'WP4', project: project, created_at: Time.now - 3.minutes)
  end

  let(:sort_by) { ::Components::WorkPackages::SortBy.new }
  let(:dialog) { ::Components::ConfirmationDialog.new }

  before do
    login_as(user)

    work_package_1
    work_package_2
    work_package_3
    work_package_4

    wp_table.visit!
    wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4
  end

  include_context 'ui-select helpers'

  it 'can sort table rows via DragNDrop' do
    wp_table.drag_and_drop_work_package from: 1, to: 3

    wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4

    wp_table.save_as 'Manual sorted query'

    wp_table.expect_and_dismiss_notification message: 'Successful creation.'

    query = Query.last
    expect(query.name).to eq 'Manual sorted query'
    expect(query.ordered_work_packages)
      .to eq([work_package_1, work_package_3, work_package_2, work_package_4].map(&:id))

    wp_table.drag_and_drop_work_package from: 0, to: 2

    wp_table.expect_work_package_order work_package_3, work_package_1, work_package_2, work_package_4

    sleep 2

    # Saved automatically
    query.reload
    expect(query.ordered_work_packages)
      .to eq([work_package_3, work_package_1, work_package_2, work_package_4].map(&:id))
  end

  it 'saves the changed order in a previously saved query' do
    wp_table.save_as 'Manual sorted query'

    sort_by.open_modal
    sort_by.update_sorting_mode 'manual'
    sort_by.apply_changes

    wp_table.drag_and_drop_work_package from: 1, to: 3
    wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4

    sleep 2

    query = Query.last
    expect(query.name).to eq 'Manual sorted query'
    expect(query.ordered_work_packages)
      .to eq([work_package_1, work_package_3, work_package_2, work_package_4].map(&:id))
  end

  it 'does not loose the current order when switching to manual sorting' do
    # Sort by creation date
    sort_by.update_criteria 'Created on'
    wp_table.expect_work_package_order work_package_4, work_package_3, work_package_2, work_package_1

    # Enable manual sorting
    sort_by.open_modal
    sort_by.update_sorting_mode 'manual'
    sort_by.apply_changes

    # Expect same order
    wp_table.expect_work_package_order work_package_4, work_package_3, work_package_2, work_package_1
  end

  it 'shows a warning when switching from manual to automatic sorting' do
    wp_table.drag_and_drop_work_package from: 1, to: 3

    wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4

    # Try to sort by creation date
    sort_by.sort_via_header 'Subject'

    # Shows a warning
    dialog.expect_open
    dialog.confirm
    wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4
  end

end
