#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package timeline hierarchies",
               :js,
               :selenium do
  let(:user) { create(:admin) }
  let!(:wp_root) do
    create(:work_package,
           project:)
  end
  let!(:wp_leaf) do
    create(:work_package,
           project:,
           parent: wp_root,
           start_date: Date.current,
           due_date: 5.days.from_now)
  end
  let!(:query) do
    query              = build(:query_with_view_gantt, user:, project:)
    query.column_names = ["subject"]
    query.filters.clear
    query.show_hierarchies = true
    query.timeline_visible = true

    query.save!
    query
  end
  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking gantt]) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }

  before do
    login_as(user)
  end

  it "hides the row in both hierarchy and timeline" do
    wp_timeline.visit_query query

    # Expect root and leaf visible in table and timeline
    wp_timeline.expect_work_package_listed(wp_root, wp_leaf)

    # Hide the hierarchy root
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_leaf)

    # Toggling hierarchies hides the inner children
    hierarchy.toggle_row(wp_root)

    # Root, other showing
    wp_timeline.expect_work_package_listed(wp_root)
    # Inter, Leaf hidden
    hierarchy.expect_hidden(wp_leaf)
    wp_timeline.expect_hidden_row(wp_leaf)

    # Should now have exactly two rows (one in each split view)
    expect(page).to have_css(".wp--row", count: 2)
  end

  context "with a relation being rendered to a hidden row" do
    let!(:wp_other) do
      create(:work_package,
             project:,
             start_date: 5.days.from_now,
             due_date: 10.days.from_now)
    end
    let!(:relation) do
      create(:relation,
             from: wp_leaf,
             to: wp_other,
             relation_type: Relation::TYPE_FOLLOWS)
    end

    it "does not render the relation when hierarchy is collapsed" do
      wp_timeline.visit_query query

      # Expect root and leaf visible in table and timeline
      wp_timeline.expect_work_package_listed(wp_root, wp_leaf, wp_other)
      wp_timeline.expect_timeline_relation(wp_leaf, wp_other)

      # Toggling hierarchies hides the inner children
      hierarchy.toggle_row(wp_root)

      wp_timeline.expect_work_package_listed(wp_root, wp_other)
      hierarchy.expect_hidden(wp_leaf)

      # Relation should now not be rendered
      wp_timeline.expect_no_timeline_relation(wp_leaf, wp_other)
      wp_timeline.expect_no_relations
    end
  end
end
