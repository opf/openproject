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

RSpec.feature 'Work package timeline navigation', js: true, selenium: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }

  let(:work_package) do
    FactoryGirl.create :work_package,
                       project: project,
                       start_date: Date.today,
                       due_date: (Date.today + 5.days)
  end

  before do
    work_package
    login_as(user)
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

    # Expect zoom at days
    wp_timeline.expect_zoom_at :days
    wp_timeline.zoom_out
    wp_timeline.expect_zoom_at :weeks

    # Save the query
    settings_menu.open_and_save_query 'foobar'
    wp_timeline.expect_title 'foobar'

    # Check the query
    query = Query.last
    expect(query.timeline_visible).to be_truthy

    # Revisit page
    wp_timeline.visit_query query
    wp_timeline.expect_work_package_listed(work_package)
    wp_timeline.expect_timeline!(open: true)
    wp_timeline.expect_timeline_element(work_package)

    # Expect zoom at days
    wp_timeline.expect_zoom_at :weeks
    wp_timeline.zoom_in
    wp_timeline.expect_zoom_at :days
  end

  describe 'with a hierarchy being shown' do
    let!(:child_work_package) do
      FactoryGirl.create :work_package,
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
    let(:project) { FactoryGirl.create(:project) }
    let(:category) { FactoryGirl.create :category, project: project, name: 'Foo' }
    let(:category2) { FactoryGirl.create :category, project: project, name: 'Bar' }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:relations) { ::Components::WorkPackages::Relations.new(wp_cat1) }

    let!(:wp_cat1) do
      FactoryGirl.create :work_package,
                         project: project,
                         category: category,
                         start_date: Date.today,
                         due_date: (Date.today + 5.days)
    end
    let!(:wp_cat2) do
      FactoryGirl.create :work_package,
                         project: project,
                         category: category2,
                         start_date: Date.today + 5.days,
                         due_date: (Date.today + 10.days)
    end
    let!(:wp_none) do
      FactoryGirl.create :work_package,
                         project: project
    end

    let!(:relation) do
      FactoryGirl.create(:relation,
                         from: wp_cat1,
                         to: wp_cat2,
                         relation_type: Relation::TYPE_FOLLOWS)
    end

    let!(:query) do
      query              = FactoryGirl.build(:query, user: user, project: project)
      query.column_names = ['subject', 'category']
      query.show_hierarchies = false
      query.timeline_visible = true

      query.save!
      query
    end

    it 'mirrors group handling when grouping by category' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_cat1, wp_cat2, wp_none)

      # Group by category
      wp_table.click_setting_item 'Group by ...'
      select 'Category', from: 'selected_columns_new'
      click_button 'Apply'

      # Expect table to be grouped as WP created above
      expect(page).to have_selector('.group--value .count', count: 3)

      # Expect timeline to have relation between first and second group
      wp_timeline.expect_timeline_relation(wp_cat1, wp_cat2)

      # Collapse first section
      find('#wp-table-rowgroup-1 .expander').click
      wp_timeline.expect_work_package_not_listed(wp_cat1)

      # Relation should be hidden
      wp_timeline.expect_no_timeline_relation(wp_cat1, wp_cat2)
    end

    it 'removes the relation element when removed in split screen' do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(wp_cat1, wp_cat2, wp_none)

      # Expect timeline to have relation between first and second group
      wp_timeline.expect_timeline_relation(wp_cat1, wp_cat2)
      wp_timeline.expect_timeline_element(wp_cat1)
      wp_timeline.expect_timeline_element(wp_cat2)

      split_view = wp_table.open_split_view(wp_cat1)
      split_view.switch_to_tab tab: :relations

      relations.remove_relation(wp_cat2)

      # Relation should be removed in TL
      wp_timeline.expect_timeline_element(wp_cat1)
      wp_timeline.expect_timeline_element(wp_cat2)
      wp_timeline.expect_no_timeline_relation(wp_cat1, wp_cat2)
    end
  end
end
