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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Dragging work packages in and between sprints",
               :js, :selenium, :settings_reset do
  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w(work_package_tracking backlogs))
  end
  let!(:project2) { create(:project) }
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           manage_sprint_items
                           view_work_packages
                           edit_work_packages))
  end
  let(:edit_role_without_manage_sprint_items) do
    create(:project_role,
           permissions: %i(view_sprints
                           view_work_packages
                           edit_work_packages))
  end

  let(:type) { create(:type) }

  let!(:sprint1) { create(:sprint, project:) }
  let!(:sprint2) { create(:sprint, project:) }

  let!(:sprint1_wp1) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_wp2) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_wp3) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_wp4) { create(:work_package, sprint: sprint1, type:, project:) }
  let!(:sprint1_other_project_wp1) { create(:work_package, sprint: sprint1, type:, project: project2) }
  let!(:sprint1_other_project_wp2) { create(:work_package, sprint: sprint1, type:, project: project2) }
  let!(:sprint1_other_project_wp3) { create(:work_package, sprint: sprint1, type:, project: project2) }
  let!(:bucket) { create(:backlog_bucket, project:, name: "Backlog bucket") }
  let!(:bucket_wp1) { create(:work_package, backlog_bucket: bucket, position: 1, type:, project:) }
  let!(:bucket_wp2) { create(:work_package, backlog_bucket: bucket, position: 2, type:, project:) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_roles: {
             project => manage_sprint_items_role,
             project2 => manage_sprint_items_role
           })
  end

  before do
    backlogs_page.visit!
  end

  context "in a non shared sprint" do
    it "displays work packages in correct order and allows dragging them around" do
      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_wp1,
                                                                 sprint1_wp2,
                                                                 sprint1_wp3,
                                                                 sprint1_wp4])
      backlogs_page
        .drag_work_package(sprint1_wp1, before: sprint1_wp4)

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_wp2,
                                                                 sprint1_wp3,
                                                                 sprint1_wp1,
                                                                 sprint1_wp4])
      backlogs_page
        .drag_work_package(sprint1_wp1, before: sprint1_wp3)

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_wp2,
                                                                 sprint1_wp1,
                                                                 sprint1_wp3,
                                                                 sprint1_wp4])

      backlogs_page
        .drag_work_package(sprint1_wp1, into: sprint2)

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_wp2,
                                                                 sprint1_wp3,
                                                                 sprint1_wp4])
      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint2,
                                                 work_packages: [sprint1_wp1])
    end

    context "when the sprint item was morphed by a Turbo update" do
      it "allows dragging the morphed item" do
        backlogs_page.click_in_sprint_story_move_menu(sprint1_wp2, "Move down")
        backlogs_page.expect_work_packages_in_sprint_in_order(sprint1,
                                                              work_packages: [sprint1_wp1,
                                                                              sprint1_wp3,
                                                                              sprint1_wp2,
                                                                              sprint1_wp4])

        backlogs_page.drag_work_package(sprint1_wp2, before: sprint1_wp1)

        backlogs_page.expect_work_packages_in_sprint_in_order(sprint1,
                                                              work_packages: [sprint1_wp2,
                                                                              sprint1_wp1,
                                                                              sprint1_wp3,
                                                                              sprint1_wp4])
      end
    end

    it "keeps drop indicators active after moving a bucket item into the sprint" do
      backlogs_page.drag_work_package(bucket_wp2, before: sprint1_wp4)
      backlogs_page.expect_work_packages_in_sprint_in_order(
        sprint1,
        work_packages: [sprint1_wp1, sprint1_wp2, sprint1_wp3, bucket_wp2, sprint1_wp4]
      )

      backlogs_page.drag_work_package(sprint1_wp1, before: sprint1_wp3)

      dnd_probe_state = page.evaluate_script(<<~JS)
        window.__opBacklogsDndProbeState
      JS
      drop_positions = dnd_probe_state.fetch("events").flat_map { |event| event.fetch("dropPositions") }

      expect(drop_positions)
        .to include({ "itemId" => sprint1_wp3.id.to_s, "position" => "top" }),
            JSON.pretty_generate(dnd_probe_state)
    end
  end

  context "when lacking the permission to manage sprint items" do
    current_user do
      create(:user,
             member_with_roles: {
               project => edit_role_without_manage_sprint_items
             })
    end

    it "displays work packages in correct order but does not allow dragging them around" do
      backlogs_page.expect_work_package_not_draggable(sprint1_wp1)
      backlogs_page.expect_work_package_not_draggable(sprint1_wp2)
      backlogs_page.expect_work_package_not_draggable(sprint1_wp3)
      backlogs_page.expect_work_package_not_draggable(sprint1_wp4)
    end
  end

  context "in a shared sprint" do
    let(:backlogs_page) { Pages::Backlog.new(project2) }

    it "displays work packages in correct order and allows dragging them around in a shared sprint" do
      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_other_project_wp1,
                                                                 sprint1_other_project_wp2,
                                                                 sprint1_other_project_wp3])
      backlogs_page
        .drag_work_package(sprint1_other_project_wp1, before: sprint1_other_project_wp3)

      backlogs_page
        .expect_work_packages_in_sprint_in_order(sprint1,
                                                 work_packages: [sprint1_other_project_wp2,
                                                                 sprint1_other_project_wp1,
                                                                 sprint1_other_project_wp3])
    end
  end
end
