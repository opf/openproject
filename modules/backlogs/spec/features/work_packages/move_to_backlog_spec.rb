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

RSpec.describe "Move to backlog", :js do
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }

  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages manage_sprint_items
                           add_work_packages create_sprints show_board_views manage_board_views]
           })
  end
  let(:planning_page) { Pages::Backlog.new(project) }

  let!(:sprint) do
    create(:sprint, project:, start_date: Date.yesterday, finish_date: Date.tomorrow)
  end
  let!(:bucket_a) { create(:backlog_bucket, project:, name: "Bucket A") }
  let!(:bucket_b) { create(:backlog_bucket, project:, name: "Bucket B") }

  current_user { user }

  describe "Move to inbox" do
    context "when in a sprint" do
      let!(:work_package) { create(:work_package, project:, sprint:) }

      it "moves the work package to the backlog inbox" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to inbox")

        planning_page.expect_work_package_not_in_sprint(work_package, sprint)
        planning_page.expect_inbox_item(work_package)
      end
    end

    context "when in a bucket" do
      let!(:work_package) { create(:work_package, project:, backlog_bucket: bucket_a) }

      it "moves the work package to the backlog inbox" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to inbox")

        planning_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)
        planning_page.expect_inbox_item(work_package)
      end
    end
  end

  describe "Move to backlog bucket" do
    context "when in a sprint" do
      let!(:work_package) { create(:work_package, project:, sprint:) }

      it "opens the dialog and moves the work package to the selected bucket" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to backlog bucket")

        within_modal "Move to backlog bucket" do
          select bucket_b.name, from: "target_id"
          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_work_package_not_in_sprint(work_package, sprint)
        planning_page.expect_work_package_in_backlog_bucket(work_package, bucket_b)
      end
    end

    context "when in the inbox" do
      let!(:work_package) { create(:work_package, project:) }

      it "opens the dialog and moves the work package to the selected bucket" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to backlog bucket")

        within_modal "Move to backlog bucket" do
          select bucket_a.name, from: "target_id"
          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_no_inbox_item(work_package)
        planning_page.expect_work_package_in_backlog_bucket(work_package, bucket_a)
      end
    end

    context "when in a bucket" do
      let!(:work_package) { create(:work_package, project:, backlog_bucket: bucket_a) }

      it "opens the dialog excluding the current bucket, and moves to another bucket" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to backlog bucket")

        within_modal "Move to backlog bucket" do
          expect(page).to have_no_css("option", text: bucket_a.name)
          expect(page).to have_css("option", text: bucket_b.name)

          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)
        planning_page.expect_work_package_in_backlog_bucket(work_package, bucket_b)
      end
    end
  end

  describe "Move to sprint" do
    context "when in a sprint" do
      let!(:second_sprint) do
        create(:sprint, project:, start_date: 1.week.from_now.to_date, finish_date: 2.weeks.from_now.to_date)
      end
      let!(:work_package) { create(:work_package, project:, sprint:) }

      it "opens the dialog excluding the current sprint, and moves to another sprint" do
        planning_page.visit!
        planning_page.expect_work_package_in_sprint(work_package, sprint)

        planning_page.click_in_work_package_move_submenu(work_package, "Move to sprint", wait: false)

        within_modal "Move to sprint" do
          expect(page).to have_no_select("target_id", with_options: [sprint.name])
          expect(page).to have_select("target_id", with_options: [second_sprint.name])

          select second_sprint.name, from: "target_id"
          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_work_package_not_in_sprint(work_package, sprint)
        planning_page.expect_work_package_in_sprint(work_package, second_sprint)
      end
    end

    context "when in the inbox" do
      let!(:work_package) { create(:work_package, project:) }

      it "opens the dialog and moves the work package to the selected sprint" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to sprint")

        within_modal "Move to sprint" do
          select sprint.name, from: "target_id"
          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_no_inbox_item(work_package)
        planning_page.expect_work_package_in_sprint(work_package, sprint)
      end
    end

    context "when in a bucket" do
      let!(:work_package) { create(:work_package, project:, backlog_bucket: bucket_a) }

      it "opens the dialog and moves the work package to the selected sprint" do
        planning_page.visit!
        planning_page.click_in_work_package_move_submenu(work_package, "Move to sprint", wait: false)

        within_modal "Move to sprint" do
          select sprint.name, from: "target_id"
          click_on "Move"
        end

        wait_for_network_idle

        planning_page.expect_work_package_not_in_backlog_bucket(work_package, bucket_a)
        planning_page.expect_work_package_in_sprint(work_package, sprint)
      end
    end
  end
end
