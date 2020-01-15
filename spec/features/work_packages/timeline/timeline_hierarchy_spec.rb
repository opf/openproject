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

RSpec.feature 'Work package timeline hierarchies', js: true, selenium: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }

  before do
    login_as(user)
  end

  let!(:wp_root) do
    FactoryBot.create :work_package,
                       project: project
  end

  let!(:wp_leaf) do
    FactoryBot.create :work_package,
                       project: project,
                       parent: wp_root,
                       start_date: Date.today,
                       due_date: (Date.today + 5.days)
  end

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject']
    query.filters.clear
    query.show_hierarchies = true
    query.timeline_visible = true

    query.save!
    query
  end

  it 'hides the row in both hierarchy and timeline' do
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
    expect(page).to have_selector('.wp--row', count: 2)
  end

  context 'with a relation being rendered to a hidden row' do
    let!(:wp_other) do
      FactoryBot.create :work_package,
                         project: project,
                         start_date: Date.today + 5.days,
                         due_date: (Date.today + 10.days)
    end
    let!(:relation) do
      FactoryBot.create(:relation,
                         from: wp_leaf,
                         to: wp_other,
                         relation_type: Relation::TYPE_FOLLOWS)
    end

    it 'does not render the relation when hierarchy is collapsed' do
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
