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

describe 'Manual sorting of WP table', type: :feature, js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:type_task) { FactoryBot.create :type_task }
  let(:type_bug) { FactoryBot.create :type_bug }
  let(:project) { FactoryBot.create(:project, types: [type_task, type_bug]) }
  let(:work_package_1) do
    FactoryBot.create(:work_package, subject: 'WP1', project: project, type: type_task, created_at: Time.now)
  end
  let(:work_package_2) do
    FactoryBot.create(:work_package, subject: 'WP2', project: project, parent: work_package_1, type: type_task, created_at: Time.now - 1.minutes)
  end
  let(:work_package_3) do
    FactoryBot.create(:work_package, subject: 'WP3', project: project, parent: work_package_2, type: type_bug, created_at: Time.now - 2.minutes)
  end
  let(:work_package_4) do
    FactoryBot.create(:work_package, subject: 'WP4', project: project, parent: work_package_3, type: type_bug, created_at: Time.now - 3.minutes)
  end

  let(:sort_by) { ::Components::WorkPackages::SortBy.new }
  let(:hierarchies) { ::Components::WorkPackages::Hierarchies.new }
  let(:dialog) { ::Components::ConfirmationDialog.new }

  before do
    login_as(user)

    work_package_1
    work_package_2
    work_package_3
    work_package_4
  end

  describe 'hierarchy mode' do
    before do
      wp_table.visit!

      # Hierarchy enabled
      wp_table.expect_work_package_order(work_package_1, work_package_2, work_package_3, work_package_4)
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2, work_package_3)
      hierarchies.expect_leaf_at(work_package_4)
    end

    it 'maintains the order until saved' do
      wp_table.drag_and_drop_work_package from: 3, to: 1
      loading_indicator_saveguard
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
      hierarchies.expect_leaf_at(work_package_4, work_package_3)

      expect(page).to have_selector('.editable-toolbar-title--save')
      wp_table.save_as "My sorted query"

      wp_table.expect_and_dismiss_notification message: 'Successful creation.'

      query = nil
      retry_block do
        query = Query.last
        raise "Query was not yet saved." unless query.name == 'My sorted query'
      end

      expect(query.ordered_work_packages)
        .to eq([work_package_1, work_package_4, work_package_2, work_package_3].map(&:id))
    end

    it 'can drag an element into a hierarchy' do
      # Move up the hierarchy
      wp_table.drag_and_drop_work_package from: 3, to: 1
      loading_indicator_saveguard
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
      hierarchies.expect_leaf_at(work_package_3, work_package_4)

      # Keep after table refresh
      page.driver.browser.navigate.refresh
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
      hierarchies.expect_leaf_at(work_package_3, work_package_4)
    end

    it 'can drag an element out of the hierarchy' do
      # Move up the hierarchy
      wp_table.drag_and_drop_work_package from: 3, to: 0
      loading_indicator_saveguard
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
      hierarchies.expect_leaf_at(work_package_4)

      # Expect WP has no parent
      wp_page = Pages::SplitWorkPackage.new(work_package_4)
      wp_page.visit!
      wp_page.expect_no_parent

      # Keep after table refresh
      page.driver.browser.navigate.refresh
      hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
      hierarchies.expect_leaf_at(work_package_3, work_package_4)
      wp_page.expect_no_parent
    end
  end

  describe 'group mode' do
    describe 'group by type' do
      let(:group_by) { ::Components::WorkPackages::GroupBy.new }

      it 'updates the work packages appropriately' do
        wp_table.visit!
        group_by.enable_via_menu 'Type'

        wp_table.save_as 'Type query'
        wp_table.expect_and_dismiss_notification message: 'Successful creation.'

        expect(page).to have_selector('.group--value', text: 'Task (2)')
        expect(page).to have_selector('.group--value', text: 'Bug (2)')

        wp_table.drag_and_drop_work_package from: 0, to: 3

        expect(page).to have_selector('.group--value', text: 'Task (1)')
        expect(page).to have_selector('.group--value', text: 'Bug (3)')
      end
    end
  end

  describe 'flat mode' do
    before do
      wp_table.visit!
      hierarchies.disable_via_header
      wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4
    end

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

    context 'the gantt chart' do
      let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

      it 'reloads after drop' do
        wp_timeline.toggle_timeline
        wp_timeline.expect_timeline!
        wp_timeline.expect_row_count(4)

        wp_timeline.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4

        wp_table.drag_and_drop_work_package from: 1, to: 3
        wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4
        wp_timeline.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4
      end
    end
  end
end
