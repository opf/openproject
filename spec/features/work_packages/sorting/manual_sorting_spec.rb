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
    FactoryBot.create(:work_package,
                      subject: 'WP2',
                      project: project,
                      parent: work_package_1,
                      type: type_task,
                      created_at: Time.now - 1.minutes)
  end
  let(:work_package_3) do
    FactoryBot.create(:work_package,
                      subject: 'WP3',
                      project: project,
                      parent: work_package_2,
                      type: type_bug,
                      created_at: Time.now - 2.minutes)
  end
  let(:work_package_4) do
    FactoryBot.create(:work_package,
                      subject: 'WP4',
                      project: project,
                      parent: work_package_3,
                      type: type_bug,
                      created_at: Time.now - 3.minutes)
  end

  let(:sort_by) { ::Components::WorkPackages::SortBy.new }
  let(:hierarchies) { ::Components::WorkPackages::Hierarchies.new }
  let(:dialog) { ::Components::ConfirmationDialog.new }
  let(:pagination) { ::Components::TablePagination.new }

  def expect_query_order(query, expected)
    retry_block do
      query.reload

      # work_package_4 was not positioned
      found = query.ordered_work_packages.pluck(:work_package_id)

      raise "Backend order is incorrect: #{found} != #{expected}" unless found == expected
    end
  end

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

      # Expect sorted 1 and 2, the rest is not positioned
      expect_query_order(query, [work_package_1, work_package_4].map(&:id))

      # Pagination information is shown but no per page options
      pagination.expect_range(1, 4, 4)
      pagination.expect_no_per_page_options
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

    it 'can drag an element completely out of the hierarchy' do
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

    context 'drag an element partly out of the hierarchy' do
      let(:work_package_5) do
        FactoryBot.create(:work_package, subject: 'WP5', project: project, parent: work_package_1)
      end
      let(:work_package_6) do
        FactoryBot.create(:work_package, subject: 'WP6', project: project, parent: work_package_1)
      end

      before do
        work_package_5
        work_package_6
        work_package_4.parent = work_package_2
        work_package_4.save!
        wp_table.visit!

        # Hierarchy enabled
        wp_table.expect_work_package_order(work_package_1,
                                           work_package_2,
                                           work_package_3,
                                           work_package_4,
                                           work_package_5,
                                           work_package_6)
        hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
        hierarchies.expect_leaf_at(work_package_3, work_package_4, work_package_5, work_package_6)
      end

      it 'move below a sibling of my parent' do
        wp_table.drag_and_drop_work_package from: 3, to: 5

        loading_indicator_saveguard
        wp_table.expect_work_package_order(work_package_1,
                                           work_package_2,
                                           work_package_3,
                                           work_package_5,
                                           work_package_4,
                                           work_package_6)
        hierarchies.expect_hierarchy_at(work_package_1, work_package_2)
        hierarchies.expect_leaf_at(work_package_3, work_package_4, work_package_5, work_package_6)
      end
    end
  end

  describe 'group mode' do
    describe 'group by type' do
      let(:group_by) { ::Components::WorkPackages::GroupBy.new }

      before do
        wp_table.visit!
        group_by.enable_via_menu 'Type'

        wp_table.save_as 'Type query'
        wp_table.expect_and_dismiss_notification message: 'Successful creation.'

        expect(page).to have_selector('.group--value', text: 'Task (2)')
        expect(page).to have_selector('.group--value', text: 'Bug (2)')
      end

      it 'updates the work packages appropriately' do
        wp_table.drag_and_drop_work_package from: 0, to: 3

        expect(page).to have_selector('.group--value', text: 'Task (1)')
        expect(page).to have_selector('.group--value', text: 'Bug (3)')
      end

      it 'dragging item with parent does not result in an error (Regression #30832)' do
        wp_table.drag_and_drop_work_package from: 1, to: 3

        expect(page).to have_selector('.group--value', text: 'Task (1)')
        expect(page).to have_selector('.group--value', text: 'Bug (3)')

        expect(page).to have_no_selector '.notification-box.error'
      end
    end
  end

  describe 'with a saved query and positions increasing from zero' do
    let(:query) do
      FactoryBot.create(:query, user: user, project: project, show_hierarchies: false).tap do |q|
        q.sort_criteria = [[:manual_sorting, 'asc']]
        q.save!
      end
    end
    let!(:status) { FactoryBot.create :default_status }
    let!(:priority) { FactoryBot.create :default_priority }

    before do
      ::OrderedWorkPackage.create(query: query, work_package: work_package_1, position: 0)
      ::OrderedWorkPackage.create(query: query, work_package: work_package_2, position: 1)
      ::OrderedWorkPackage.create(query: query, work_package: work_package_3, position: 2)
      ::OrderedWorkPackage.create(query: query, work_package: work_package_4, position: 3)
    end

    it 'can inline create a work package and it is positioned to the bottom (Regression #31078)' do
      wp_table.visit_query query
      wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4

      wp_table.click_inline_create
      subject_field = wp_table.edit_field(nil, :subject)
      subject_field.expect_active!

      # Save the WP
      subject_field.set_value 'Foobar!'
      subject_field.submit_by_enter

      wp_table.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      wp_table.expect_work_package_subject 'Foobar!'

      inline_created = WorkPackage.last
      expect(inline_created.subject).to eq 'Foobar!'

      # Wait until the order was saved, this might take a few moments
      retry_block do
        order = ::OrderedWorkPackage.find_by(query: query, work_package: inline_created)

        unless order&.position == 8195
          raise "Expected order of #{inline_created.id} to be 8195. Was: #{order&.position}. Retrying"
        end
      end

      wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4, inline_created

      # Revisit the query
      wp_table.visit_query query

      # Expect same order
      wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4, inline_created
    end
  end

  describe 'with a saved query that is NOT manually sorted' do
    let(:query) do
      FactoryBot.create(:query, user: user, project: project, show_hierarchies: false).tap do |q|
        q.sort_criteria = [[:id, 'asc']]
        q.save!
      end
    end

    it 'can drag and drop and will save the query' do
      wp_table.visit_query query
      wp_table.expect_work_package_order work_package_1, work_package_2, work_package_3, work_package_4

      wp_table.drag_and_drop_work_package from: 1, to: 3

      wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4

      wp_table.expect_and_dismiss_notification message: 'Successful update.'

      retry_block do
        query.reload

        if query.sort_criteria != [['manual_sorting', 'asc']]
          raise "Expected sort_criteria to be updated to manual_sorting, was #{query.sort_criteria.inspect}"
        end
      end

      pagination.expect_range(1, 4, 4)
      pagination.expect_no_per_page_options
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

      expect_query_order(query, [work_package_1.id, work_package_3.id, work_package_2.id])

      wp_table.drag_and_drop_work_package from: 0, to: 2

      expect_query_order(query, [work_package_3.id, work_package_1.id, work_package_2.id])
    end

    it 'saves the changed order in a previously saved query' do
      wp_table.save_as 'Manual sorted query'

      sort_by.open_modal
      sort_by.update_sorting_mode 'manual'
      sort_by.apply_changes

      wp_table.drag_and_drop_work_package from: 1, to: 3

      wp_table.expect_work_package_order work_package_1, work_package_3, work_package_2, work_package_4

      query = Query.last
      expect(query.name).to eq 'Manual sorted query'
      expect_query_order(query, [work_package_1.id, work_package_3.id, work_package_2.id])

      pagination.expect_range(1, 4, 4)
      pagination.expect_no_per_page_options
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
