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

RSpec.describe "Backlog quick search and advanced filters", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end

  shared_let(:user) { create(:admin) }

  shared_let(:status_a) { create(:status, name: "Status A", is_default: true) }
  shared_let(:status_b) { create(:status, name: "Status B") }
  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:sprint) { create(:sprint, project:) }

  def create_bucket_wp(subject:, status: status_a, backlog_bucket: bucket)
    create(:work_package, project:, backlog_bucket:, status:, subject:)
  end

  def create_inbox_wp(subject:, status: status_a)=create_bucket_wp(subject:, status:, backlog_bucket: nil)
  def create_sprint_wp(subject:, status: status_a)=create(:work_package, project:, sprint:, status:, subject:)

  shared_let(:matching_bucket_wp) { create_bucket_wp(subject: "Keep the Needle in a haystack") }
  shared_let(:excluded_bucket_wp) { create_bucket_wp(subject: "Unrelated subject") }
  shared_let(:status_b_bucket_wp) { create_bucket_wp(subject: "Keep me but wrong status", status: status_b) }
  shared_let(:keep_last_bucket_wp) { create_bucket_wp(subject: "Keep last") }
  shared_let(:matching_sprint_wp) { create_sprint_wp(subject: "Keep the Needle in a haystack") }
  shared_let(:excluded_sprint_wp) { create_sprint_wp(subject: "Unrelated subject") }
  shared_let(:status_b_sprint_wp) { create_sprint_wp(subject: "Keep me but wrong status", status: status_b) }

  shared_let(:matching_inbox_wp) { create_inbox_wp(subject: "Keep the Needle in a haystack") }
  shared_let(:excluded_inbox_wp) { create_inbox_wp(subject: "Unrelated subject") }
  shared_let(:status_b_inbox_wp) { create_inbox_wp(subject: "Keep me but wrong status", status: status_b) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { user }

  before { backlogs_page.visit! }

  it "narrows the listings as the subject quick search is typed" do
    backlogs_page.expect_bucket_items(
      bucket, items: [matching_bucket_wp, excluded_bucket_wp, status_b_bucket_wp, keep_last_bucket_wp]
    )
    backlogs_page.expect_backlog_bucket_work_package_count(bucket, 4)

    backlogs_page.expect_sprint_items(sprint, items: [matching_sprint_wp, excluded_sprint_wp, status_b_sprint_wp])
    backlogs_page.expect_sprint_work_package_count(sprint, 3)

    backlogs_page.expect_inbox_items(items: [matching_inbox_wp, excluded_inbox_wp, status_b_inbox_wp])
    backlogs_page.expect_inbox_work_package_count(3)

    backlogs_page.apply_subject_filter("Needle")

    backlogs_page.expect_bucket_items(bucket, items: matching_bucket_wp)
    backlogs_page.expect_no_bucket_items(bucket, items: [excluded_bucket_wp, status_b_bucket_wp, keep_last_bucket_wp])
    backlogs_page.expect_backlog_bucket_work_package_count(bucket, 1)

    backlogs_page.expect_sprint_items(sprint, items: matching_sprint_wp)
    backlogs_page.expect_no_sprint_items(sprint, items: [excluded_sprint_wp, status_b_sprint_wp])
    backlogs_page.expect_sprint_work_package_count(sprint, 1)

    backlogs_page.expect_inbox_items(items: matching_inbox_wp)
    backlogs_page.expect_no_inbox_items(items: [excluded_inbox_wp, status_b_inbox_wp])
    backlogs_page.expect_inbox_work_package_count(1)
  end

  it "narrows the listings when an advanced filter is applied" do
    backlogs_page.expect_bucket_items(bucket, items: status_b_bucket_wp)
    backlogs_page.expect_sprint_items(sprint, items: status_b_sprint_wp)
    backlogs_page.expect_inbox_items(items: status_b_inbox_wp)

    backlogs_page.apply_status_filter(status_b)

    backlogs_page.expect_bucket_items(bucket, items: status_b_bucket_wp)
    backlogs_page.expect_no_bucket_items(bucket, items: [matching_bucket_wp, excluded_bucket_wp, keep_last_bucket_wp])
    backlogs_page.expect_backlog_bucket_work_package_count(bucket, 1)

    backlogs_page.expect_sprint_items(sprint, items: status_b_sprint_wp)
    backlogs_page.expect_no_sprint_items(sprint, items: [matching_sprint_wp, excluded_sprint_wp])
    backlogs_page.expect_sprint_work_package_count(sprint, 1)

    backlogs_page.expect_inbox_items(items: status_b_inbox_wp)
    backlogs_page.expect_no_inbox_items(items: [matching_inbox_wp, excluded_inbox_wp])
    backlogs_page.expect_inbox_work_package_count(1)
  end

  context "when executing various actions on the page with filters applied" do
    shared_let(:other_bucket) { create(:backlog_bucket, project:) }
    shared_let(:sprint_kept_wp) do
      create(:work_package, project:, sprint:, status: status_a, subject: "Keep me sprint A")
    end
    shared_let(:sprint_kept_wp2) do
      create(:work_package, project:, sprint:, status: status_a, subject: "Keep me sprint B")
    end
    shared_let(:empty_target_bucket) { create(:backlog_bucket, project:) }
    shared_let(:existing_wp) { create_bucket_wp(subject: "Filtered out", backlog_bucket: empty_target_bucket) }
    shared_let(:draggable_wp) { create_bucket_wp(subject: "Keep draggable") }

    before do
      backlogs_page.apply_subject_filter("Keep")
      backlogs_page.apply_status_filter(status_a)
      backlogs_page.close_filters
    end

    def expect_filters_preserved
      expect(page).to have_field("Search by subject", with: "Keep")
      backlogs_page.expect_no_bucket_items(bucket, items: [excluded_bucket_wp, status_b_bucket_wp])
      backlogs_page.expect_no_sprint_items(sprint, items: [excluded_sprint_wp, status_b_sprint_wp])
      backlogs_page.expect_no_inbox_items(items: [excluded_inbox_wp, status_b_inbox_wp])
    end

    it "preserves the filters after a cross-bucket drag and drop", :selenium do
      backlogs_page.drag_work_package_to_backlog_bucket(matching_bucket_wp, other_bucket)

      expect_filters_preserved
      backlogs_page.expect_bucket_items(other_bucket, items: matching_bucket_wp)
      backlogs_page.expect_bucket_items(bucket, items: keep_last_bucket_wp)
    end

    it "preserves the filters after opening and closing the work package details" do
      details_view = backlogs_page.open_work_package_details(matching_bucket_wp)
      details_view.close

      expect(page).to have_current_path project_backlogs_backlog_path(project), ignore_query: true
      expect_filters_preserved
      backlogs_page.expect_bucket_items(bucket, items: matching_bucket_wp)
    end

    it "preserves the filters after moving work packages up or down" do
      backlogs_page.click_in_work_package_move_submenu(keep_last_bucket_wp, "Move up")

      expect_filters_preserved
      backlogs_page.expect_bucket_items_in_order(bucket, items: [keep_last_bucket_wp, matching_bucket_wp])

      backlogs_page.click_in_sprint_story_move_menu(sprint_kept_wp2, "Move up")

      expect_filters_preserved
      backlogs_page.expect_sprint_items_in_order(sprint, items: [sprint_kept_wp2, sprint_kept_wp])
    end

    it "persists the drop position among the visible siblings", :selenium do
      backlogs_page.expect_no_bucket_items(bucket, items: excluded_bucket_wp)
      backlogs_page.expect_bucket_items_in_order(
        bucket,
        items: [matching_bucket_wp, keep_last_bucket_wp, draggable_wp]
      )

      backlogs_page.drag_work_package(matching_bucket_wp, after: keep_last_bucket_wp)

      backlogs_page.clear_subject_filter

      backlogs_page.expect_bucket_items_in_order(
        bucket,
        items: [excluded_bucket_wp, keep_last_bucket_wp, matching_bucket_wp, draggable_wp]
      )
    end

    it "persists the move-up position among the visible siblings" do
      backlogs_page.expect_no_bucket_items(bucket, items: excluded_bucket_wp)
      backlogs_page.expect_bucket_items_in_order(
        bucket,
        items: [matching_bucket_wp, keep_last_bucket_wp, draggable_wp]
      )

      backlogs_page.click_in_work_package_move_submenu(keep_last_bucket_wp, "Move up")

      backlogs_page.clear_subject_filter

      backlogs_page.expect_bucket_items_in_order(
        bucket,
        items: [keep_last_bucket_wp, matching_bucket_wp, excluded_bucket_wp, draggable_wp]
      )
    end

    it "inserts the dragged work package at the top of the bucket's real list", :selenium do
      backlogs_page.expect_backlog_bucket_blankslate(empty_target_bucket, filtered: true)

      backlogs_page.drag_work_package_to_backlog_bucket(draggable_wp, empty_target_bucket)

      backlogs_page.clear_subject_filter

      backlogs_page.expect_bucket_items_in_order(
        empty_target_bucket, items: [draggable_wp, existing_wp]
      )
    end
  end
end
