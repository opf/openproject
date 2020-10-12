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

RSpec.feature 'Work package timeline navigation', js: true, selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:query_menu) { Components::WorkPackages::QueryMenu.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  let(:work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      start_date: Date.today,
                      due_date: (Date.today + 5.days)
  end

  before do
    work_package
    login_as(user)
  end

  describe 'with multiple queries' do
    let(:type) { FactoryBot.create :type }
    let(:type2) { FactoryBot.create :type }
    let(:project) { FactoryBot.create(:project, types: [type, type2]) }

    let!(:work_package) do
      FactoryBot.create :work_package,
                        project: project,
                        type: type
    end

    let!(:work_package2) do
      FactoryBot.create :work_package,
                        project: project,
                        type: type2
    end

    let!(:query) do
      query = FactoryBot.build(:query, user: user, project: project)
      query.column_names = ['id', 'type', 'subject']
      query.filters.clear
      query.timeline_visible = false
      query.add_filter('type_id', '=', [type.id])
      query.name = 'Query without Timeline'

      query.save!
      query
    end

    let!(:query_tl) do
      query = FactoryBot.build(:query, user: user, project: project)
      query.column_names = ['id', 'type', 'subject']
      query.filters.clear
      query.add_filter('type_id', '=', [type2.id])
      query.timeline_visible = true
      query.name = 'Query with Timeline'

      query.save!
      query
    end

    it 'can move from and to the timeline query (Regression test #26086)' do
      # Visit timeline query
      wp_timeline.visit_query query_tl

      wp_timeline.expect_timeline!(open: true)
      wp_timeline.expect_work_package_listed work_package2
      wp_timeline.ensure_work_package_not_listed! work_package

      # Select other query
      query_menu.select query
      wp_timeline.expect_timeline!(open: false)
      wp_timeline.expect_work_package_listed work_package
      wp_timeline.ensure_work_package_not_listed! work_package2

      # Select first query again
      query_menu.select query_tl

      wp_timeline.expect_timeline!(open: true)
      wp_timeline.expect_work_package_listed work_package2
      wp_timeline.ensure_work_package_not_listed! work_package
    end

    it 'can open a context menu in the timeline (Regression #30761)' do
      # Visit timeline query
      wp_timeline.visit_query query_tl

      wp_timeline.expect_timeline!(open: true)
      wp_timeline.expect_work_package_listed work_package2
      wp_timeline.ensure_work_package_not_listed! work_package


      retry_block do
        find(".wp-row-#{work_package2.id}-timeline").right_click
        find('.menu-item', text: 'Add predecessor')
        find('.menu-item', text: 'Add follower')
      end
    end
  end

  it 'can save the open state and zoom of timeline' do
    wp_timeline.visit!
    wp_timeline.expect_work_package_listed(work_package)

    # Should be initially closed
    wp_timeline.expect_timeline!(open: false)

    # Enable timeline
    wp_timeline.toggle_timeline
    wp_timeline.expect_timeline!(open: true)

    # Should have an active element rendered
    wp_timeline.expect_timeline_element(work_package)

    # Expect zoom out from auto to days
    wp_timeline.expect_zoom_at :auto

    # Zooming in = days
    expect(wp_timeline.zoom_in_button).to be_disabled
    wp_timeline.zoom_out
    wp_timeline.expect_zoom_at :weeks

    # Save the query
    settings_menu.open_and_save_query 'foobar'
    wp_timeline.expect_title 'foobar'

    # Check the query
    query = Query.last
    expect(query.timeline_visible).to be_truthy
    expect(query.timeline_zoom_level).to eq 'weeks'

    # Revisit page
    wp_timeline.visit_query query
    wp_timeline.expect_work_package_listed(work_package)
    wp_timeline.expect_timeline!(open: true)
    wp_timeline.expect_timeline_element(work_package)

    # Expect zoom at weeks
    wp_timeline.expect_zoom_at :weeks

    # Go back to autozoom
    wp_timeline.autozoom
    wp_timeline.expect_zoom_at :auto

    # Save
    wp_timeline.save
    wp_timeline.expect_and_dismiss_notification message: 'Successful update'

    query.reload
    expect(query.timeline_zoom_level).to eq 'auto'
  end

  describe 'with a hierarchy being shown' do
    let!(:child_work_package) do
      FactoryBot.create :work_package,
                        project: project,
                        parent: work_package,
                        start_date: Date.today,
                        due_date: (Date.today + 5.days)
    end
    let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }

    it 'toggles the hierarchy in both views' do
      wp_timeline.visit!
      wp_timeline.expect_work_package_listed(work_package)
      wp_timeline.expect_work_package_listed(child_work_package)

      # Should be initially closed
      wp_timeline.expect_timeline!(open: false)

      # Enable timeline
      wp_timeline.toggle_timeline
      wp_timeline.expect_timeline!(open: true)

      # Should have an active element rendered
      wp_timeline.expect_timeline_element(work_package)
      wp_timeline.expect_timeline_element(child_work_package)

      # Hierarchy mode is enabled by default
      hierarchy.expect_hierarchy_at(work_package)
      hierarchy.expect_leaf_at(child_work_package)

      hierarchy.toggle_row(work_package)
      hierarchy.expect_hidden(child_work_package)
      wp_timeline.expect_hidden_row(child_work_package)
    end
  end

  describe 'when table is grouped' do
    let(:project) { FactoryBot.create(:project) }
    let(:category) { FactoryBot.create :category, project: project, name: 'Foo' }
    let(:category2) { FactoryBot.create :category, project: project, name: 'Bar' }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:relations) { ::Components::WorkPackages::Relations.new(wp_cat1) }

    let!(:wp_cat1) do
      FactoryBot.create :work_package,
                        project: project,
                        category: category,
                        start_date: Date.today,
                        due_date: (Date.today + 5.days)
    end
    let!(:wp_cat2) do
      FactoryBot.create :work_package,
                        project: project,
                        category: category2,
                        start_date: Date.today + 5.days,
                        due_date: (Date.today + 10.days)
    end
    let!(:wp_none) do
      FactoryBot.create :work_package,
                        project: project
    end

    let!(:relation) do
      FactoryBot.create(:relation,
                        from: wp_cat1,
                        to: wp_cat2,
                        relation_type: Relation::TYPE_FOLLOWS)
    end

    let!(:query) do
      query = FactoryBot.build(:query, user: user, project: project)
      query.column_names = ['id', 'subject', 'category']
      query.show_hierarchies = false
      query.timeline_visible = true

      query.save!
      query
    end

    it 'mirrors group handling when grouping by category' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_cat1, wp_cat2, wp_none)

      group_by.enable_via_menu 'Category'

      # Expect table to be grouped as WP created above
      expect(page).to have_selector('.group--value .count', count: 3)

      # Expect timeline to have relation between first and second group
      wp_timeline.expect_timeline_relation(wp_cat1, wp_cat2)

      # Collapse Foo section
      header = find('.wp-table--group-header', text: 'Foo (1)')
      header.find('.expander').click
      wp_timeline.ensure_work_package_not_listed!(wp_cat1)

      # Relation should be hidden
      wp_timeline.expect_no_timeline_relation(wp_cat1, wp_cat2)
    end

    it 'removes the relation element when removed in split screen' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_cat1, wp_cat2, wp_none)

      # Expect timeline to have relation between first and second group
      within('.work-packages-split-view--tabletimeline-side') do
        wp_timeline.expect_timeline_relation(wp_cat1, wp_cat2)
        wp_timeline.expect_timeline_element(wp_cat1)
        wp_timeline.expect_timeline_element(wp_cat2)
      end

      split_view = wp_table.open_split_view(wp_cat1)
      split_view.switch_to_tab tab: :relations

      relations.remove_relation(wp_cat2)

      # Relation should be removed in TL
      within('.work-packages-split-view--tabletimeline-side') do
        wp_timeline.expect_timeline_element(wp_cat1)
        wp_timeline.expect_timeline_element(wp_cat2)
        wp_timeline.expect_no_timeline_relation(wp_cat1, wp_cat2)
      end
    end
  end
end
