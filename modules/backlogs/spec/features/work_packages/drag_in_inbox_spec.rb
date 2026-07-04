# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Dragging work packages in the inbox",
               :js, :selenium do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) { create(:project) }
  shared_let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           manage_sprint_items
                           view_work_packages
                           edit_work_packages))
  end
  shared_let(:edit_role_without_manage_sprint_items) do
    create(:project_role,
           permissions: %i(view_sprints
                           view_work_packages
                           edit_work_packages))
  end
  shared_let(:inbox_wp1) { create(:work_package, sprint: nil, project:, position: 1) }
  shared_let(:inbox_wp2) { create(:work_package, sprint: nil, project:, position: 2) }
  shared_let(:inbox_wp3) { create(:work_package, sprint: nil, project:, position: 3) }
  shared_let(:inbox_wp4) { create(:work_package, sprint: nil, project:, position: 4) }
  shared_let(:inbox_wp5) { create(:work_package, sprint: nil, project:, position: 5) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_roles: {
             project => manage_sprint_items_role
           })
  end

  it "displays work packages in correct order and allows dragging them around" do
    backlogs_page.visit!

    backlogs_page
      .expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1,
                                                              inbox_wp2,
                                                              inbox_wp3,
                                                              inbox_wp4,
                                                              inbox_wp5])
    backlogs_page
      .drag_work_package(inbox_wp1, before: inbox_wp4)

    backlogs_page
      .expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2,
                                                              inbox_wp3,
                                                              inbox_wp1,
                                                              inbox_wp4,
                                                              inbox_wp5])
    backlogs_page
      .drag_work_package(inbox_wp1, before: inbox_wp3)

    backlogs_page
      .expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2,
                                                              inbox_wp1,
                                                              inbox_wp3,
                                                              inbox_wp4,
                                                              inbox_wp5])
  end

  context "when having closed work packages at the top" do
    let(:closed_status) { create(:closed_status) }

    before do
      project.done_statuses << closed_status

      inbox_wp2.update!(status: closed_status)
      inbox_wp3.update!(status: closed_status)
    end

    it "displays work packages in correct order and allows dragging them" do
      backlogs_page.visit!

      backlogs_page
        .expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1,
                                                                inbox_wp4,
                                                                inbox_wp5])
      backlogs_page
        .drag_work_package(inbox_wp1, before: inbox_wp5)

      backlogs_page
        .expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp4,
                                                                inbox_wp1,
                                                                inbox_wp5])
    end
  end

  context "when the item was morphed by a Turbo update" do
    it "allows dragging a morphed inbox item" do
      backlogs_page.visit!

      backlogs_page.click_in_inbox_move_menu(inbox_wp2, "Move down")
      backlogs_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1,
                                                                           inbox_wp3,
                                                                           inbox_wp2,
                                                                           inbox_wp4,
                                                                           inbox_wp5])

      backlogs_page.drag_work_package(inbox_wp2, before: inbox_wp5)

      backlogs_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1,
                                                                           inbox_wp3,
                                                                           inbox_wp4,
                                                                           inbox_wp2,
                                                                           inbox_wp5])
    end
  end

  context "when the inbox is truncated" do
    # tail_size = [TRUNCATE_MIDDLE / 5, 1].max = 1, so with TRUNCATE_MIDDLE
    # stubbed to 2, the visible window is first(2) + last(1); the truncate
    # threshold (TRUNCATE_MIDDLE + tail_size * 2 = 4) stays below the 5 work
    # packages the outer example group already sets up, so the inbox truncates.
    before do
      stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 2)
    end

    it "keeps the server-rendered truncation window consistent after a same-list drag" do
      backlogs_page.visit!

      backlogs_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1, inbox_wp2])
      backlogs_page.expect_inbox_item(inbox_wp5)
      backlogs_page.expect_no_inbox_item(inbox_wp3)
      backlogs_page.expect_no_inbox_item(inbox_wp4)
      backlogs_page.expect_inbox_show_more
      expect(backlogs_page.inbox_truncation_marker_previous_item_id).to eq(inbox_wp4.id.to_s)

      # Same list, but the drop target (the inbox) is truncated: the server
      # must recompute the visible window rather than trust the optimistic
      # client-side reorder, so this move settles via a turbo-stream frame
      # reload rather than the 204/sortable-lists:moved path a plain same-list
      # drag takes. `cross_list: true` steers drag_work_package to wait on
      # that frame reload (see sortable-lists.controller.ts's `optimistic`
      # gate and Backlogs::InboxComponent's TRUNCATE_MIDDLE window).
      backlogs_page
        .drag_work_package(inbox_wp1, before: inbox_wp5, cross_list: true)

      # inbox_wp1 moved behind inbox_wp4 (the item the marker names), pushing
      # it out of the visible head and pulling inbox_wp3 into view instead.
      backlogs_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2, inbox_wp3])
      backlogs_page.expect_inbox_item(inbox_wp5)
      backlogs_page.expect_no_inbox_item(inbox_wp1)
      backlogs_page.expect_no_inbox_item(inbox_wp4)
      backlogs_page.expect_inbox_show_more
      expect(backlogs_page.inbox_truncation_marker_previous_item_id).to eq(inbox_wp1.id.to_s)
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
      backlogs_page.visit!

      backlogs_page.expect_work_package_not_draggable(inbox_wp1)
      backlogs_page.expect_work_package_not_draggable(inbox_wp2)
      backlogs_page.expect_work_package_not_draggable(inbox_wp3)
      backlogs_page.expect_work_package_not_draggable(inbox_wp4)
      backlogs_page.expect_work_package_not_draggable(inbox_wp5)
    end
  end
end
