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

RSpec.describe "Dragging work packages in backlog buckets", :js, :selenium do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end

  shared_let(:bucket_alpha) { create(:backlog_bucket, project:, name: "Alpha bucket") }
  shared_let(:bucket_beta)  { create(:backlog_bucket, project:, name: "Beta bucket") }
  shared_let(:bucket_gamma) { create(:backlog_bucket, project:, name: "Gamma bucket") }

  shared_let(:alpha_wp1) { create(:work_package, project:, backlog_bucket: bucket_alpha, position: 1) }
  shared_let(:alpha_wp2) { create(:work_package, project:, backlog_bucket: bucket_alpha, position: 2) }
  shared_let(:alpha_wp3) { create(:work_package, project:, backlog_bucket: bucket_alpha, position: 3) }
  shared_let(:gamma_wp1) { create(:work_package, project:, backlog_bucket: bucket_gamma, position: 1) }
  shared_let(:inbox_wp1) { create(:work_package, project:, backlog_bucket: nil, sprint: nil, position: 1) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages create_sprints manage_sprint_items edit_work_packages]
           })
  end

  it "reorders work packages within a bucket" do
    backlogs_page.visit!

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp1, alpha_wp2, alpha_wp3]
    )

    backlogs_page.drag_work_package(alpha_wp1, before: alpha_wp3)

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp2, alpha_wp1, alpha_wp3]
    )
  end

  it "reorders a work package to the first position in a bucket" do
    backlogs_page.visit!

    backlogs_page.drag_work_package(alpha_wp3, before: alpha_wp1)

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp3, alpha_wp1, alpha_wp2]
    )
  end

  it "does not move the first work package to the end when it is picked up and released" do
    backlogs_page.visit!

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp1, alpha_wp2, alpha_wp3]
    )

    backlogs_page.pick_up_and_release_work_package(alpha_wp1)

    backlogs_page.expect_backlogs_drop_handled_without_item_target
    backlogs_page.expect_no_backlogs_move_request
    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp1, alpha_wp2, alpha_wp3]
    )
  end

  context "when the bucket item was morphed by a Turbo update" do
    it "allows dragging the morphed item" do
      backlogs_page.visit!

      backlogs_page.click_in_inbox_move_menu(alpha_wp2, "Move down")
      backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
        bucket_alpha, work_packages: [alpha_wp1, alpha_wp3, alpha_wp2]
      )

      backlogs_page.drag_work_package(alpha_wp2, before: alpha_wp1)

      backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
        bucket_alpha, work_packages: [alpha_wp2, alpha_wp1, alpha_wp3]
      )
    end
  end

  it "moves a work package into another bucket" do
    backlogs_page.visit!

    backlogs_page.drag_work_package_to_backlog_bucket(alpha_wp1, bucket_beta)

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp2, alpha_wp3]
    )
    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_beta, work_packages: [alpha_wp1]
    )

    expect(alpha_wp1.reload.backlog_bucket_id).to eq(bucket_beta.id)
  end

  it "moves a work package from a bucket into the Inbox" do
    backlogs_page.visit!

    backlogs_page.drag_work_package_to_backlog_inbox(alpha_wp1)

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_alpha, work_packages: [alpha_wp2, alpha_wp3]
    )

    expect(alpha_wp1.reload.backlog_bucket_id).to be_nil
  end

  it "moves a work package from the Inbox into a bucket" do
    backlogs_page.visit!

    backlogs_page.drag_work_package_to_backlog_bucket(inbox_wp1, bucket_beta)

    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(
      bucket_beta, work_packages: [inbox_wp1]
    )

    expect(inbox_wp1.reload.backlog_bucket_id).to eq(bucket_beta.id)
  end

  it "hides the blankslate when dropping into a previously-empty bucket" do
    backlogs_page.visit!
    backlogs_page.expect_backlog_bucket_blankslate(bucket_beta)

    backlogs_page.drag_work_package_to_backlog_bucket(alpha_wp1, bucket_beta)

    backlogs_page.expect_no_backlog_bucket_blankslate(bucket_beta)
  end

  it "shows the blankslate after dragging the last work package out of a bucket" do
    backlogs_page.visit!
    backlogs_page.expect_no_backlog_bucket_blankslate(bucket_gamma)

    backlogs_page.drag_work_package_to_backlog_inbox(gamma_wp1)

    backlogs_page.expect_backlog_bucket_blankslate(bucket_gamma)
  end

  context "without the :manage_sprint_items permission" do
    current_user do
      create(:user,
             member_with_permissions: {
               project => %i[view_sprints view_work_packages edit_work_packages]
             })
    end

    it "does not allow dragging bucketed work packages" do
      backlogs_page.visit!

      backlogs_page.expect_work_package_not_draggable(alpha_wp1)
      backlogs_page.expect_work_package_not_draggable(alpha_wp2)
    end
  end
end
