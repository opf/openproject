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

  it 'can save the open state of timeline' do
    wp_timeline.visit!
    wp_timeline.expect_work_package_listed(work_package)

    # Should be initially closed
    wp_timeline.expect_timeline!(open: false)

    # Enable timeline
    wp_timeline.toggle_timeline
    wp_timeline.expect_timeline!(open: true)

    # Should have an active element rendered
    wp_timeline.expect_timeline_element(work_package)

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
end
