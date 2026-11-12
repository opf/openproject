# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "context_menu_shared_examples"

RSpec.describe "Work package table context menu",
               :js do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking gantt costs]) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  shared_let(:menu) { Components::WorkPackages::ContextMenu.new }
  shared_let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

  let!(:query_tl) do
    query = build(:query_with_view_gantt, user:, project:)
    query.filters.clear
    query.timeline_visible = true
    query.name = "Query with Timeline"

    query.save!

    query
  end

  before do
    login_as(user)
    work_package
  end

  context "when in the table" do
    it_behaves_like "provides a single WP context menu" do
      let(:open_context_menu) do
        -> {
          # Go to table
          wp_table.visit!
          loading_indicator_saveguard
          wp_table.expect_work_package_listed(work_package)

          # Open context menu
          menu.expect_closed
          menu.open_for(work_package)
        }
      end

      context "for multiple selected WPs" do
        let!(:work_package2) { create(:work_package, project: work_package.project) }

        it "provides a context menu with a subset of the available menu items" do
          # Go to table
          wp_table.visit!

          loading_indicator_saveguard
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          # Select all WPs
          wp_table.select_all_work_packages

          menu.open_for(work_package)
          menu.expect_options "Bulk edit", "Bulk duplicate", "Bulk change of project", "Bulk delete"
        end
      end
    end

    context "when in Gantt" do
      it "provides a context menu with timeline options" do
        wp_timeline.visit_query(query_tl)
        loading_indicator_saveguard
        wp_timeline.expect_work_package_listed(work_package)
        wp_timeline.expect_timeline!

        # Open context menu
        menu.expect_closed
        menu.open_for(work_package)
        menu.expect_options "Open details view",
                            "Open fullscreen view",
                            "Add predecessor",
                            "Add successor",
                            "Show relations"
        menu.expect_no_options "Log time"

        # Show relations tab when selecting show-relations from menu
        menu.choose("Show relations")
        expect(page).to have_current_path /details\/#{work_package.id}\/relations/
      end
    end
  end
end
