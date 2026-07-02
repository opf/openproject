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

RSpec.describe "Backlog filter panel", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end

  shared_let(:user) { create(:admin) }

  shared_let(:sprint_a) { create(:sprint, project:, name: "Sprint A") }
  shared_let(:sprint_b) { create(:sprint, project:, name: "Sprint B") }
  shared_let(:bucket_a) { create(:backlog_bucket, project:, name: "Bucket A") }
  shared_let(:bucket_b) { create(:backlog_bucket, project:, name: "Bucket B") }

  shared_let(:sprint_a_wp) { create(:work_package, project:, sprint: sprint_a) }
  shared_let(:sprint_b_wp) { create(:work_package, project:, sprint: sprint_b) }
  shared_let(:bucket_a_wp) { create(:work_package, project:, backlog_bucket: bucket_a) }
  shared_let(:bucket_b_wp) { create(:work_package, project:, backlog_bucket: bucket_b) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { user }

  before { backlogs_page.visit! }

  it "selects multiple sprint and bucket IDs simultaneously" do
    backlogs_page.expect_sprint(sprint_a)
    backlogs_page.expect_sprint(sprint_b)
    backlogs_page.expect_backlog_bucket(bucket_a)
    backlogs_page.expect_backlog_bucket(bucket_b)

    backlogs_page.apply_sprint_filter(sprint_a)

    backlogs_page.expect_sprint(sprint_a)
    backlogs_page.expect_no_sprint(sprint_b)
    backlogs_page.expect_backlog_bucket(bucket_a)
    backlogs_page.expect_backlog_bucket(bucket_b)

    backlogs_page.apply_bucket_filter(bucket_a)

    backlogs_page.expect_sprint(sprint_a)
    backlogs_page.expect_no_sprint(sprint_b)
    backlogs_page.expect_backlog_bucket(bucket_a)
    backlogs_page.expect_no_backlog_bucket(bucket_b)

    backlogs_page.apply_sprint_filter(sprint_b)

    backlogs_page.expect_sprint(sprint_a)
    backlogs_page.expect_sprint(sprint_b)
    backlogs_page.expect_backlog_bucket(bucket_a)
    backlogs_page.expect_no_backlog_bucket(bucket_b)
  end

  describe "sprint filter" do
    shared_let(:active_sprint) { create(:sprint, project:, name: "Active Sprint", status: :active) }
    shared_let(:completed_sprint) { create(:sprint, project:, name: "Completed Sprint", status: :completed) }

    it "only lists in_planning and active sprints" do
      backlogs_page.within_filter_panel(:sprint) do
        expect(page).to have_button(sprint_a.name)
        expect(page).to have_button(sprint_b.name)
        expect(page).to have_button(active_sprint.name)
        expect(page).to have_no_button(completed_sprint.name)
      end
    end
  end

  describe "bucket filter including inbox" do
    shared_let(:inbox_wp) { create(:work_package, project:) }

    it "shows inbox by default" do
      backlogs_page.expect_inbox
      backlogs_page.expect_inbox_item(inbox_wp)
    end

    it "lists inbox at the bottom of the bucket filter panel" do
      backlogs_page.within_filter_panel(:backlog_bucket) do
        item_labels = page.all("[role='option']").map { |el| el.text.strip }
        expect(item_labels.last).to eq(I18n.t(:label_inbox))
      end
    end

    it "hides inbox when bucket filter is applied without inbox" do
      backlogs_page.apply_bucket_filter(bucket_a)
      backlogs_page.expect_no_inbox
      backlogs_page.expect_backlog_bucket(bucket_a)
      backlogs_page.expect_no_backlog_bucket(bucket_b)
    end

    it "shows inbox when bucket filter includes inbox" do
      backlogs_page.apply_bucket_filter(bucket_a, include_inbox: true)
      backlogs_page.expect_inbox
      backlogs_page.expect_inbox_item(inbox_wp)
      backlogs_page.expect_backlog_bucket(bucket_a)
      backlogs_page.expect_no_backlog_bucket(bucket_b)
    end
  end

  describe "clear button" do
    it "clears the sprint filter while preserving the bucket filter" do
      backlogs_page.apply_sprint_filter(sprint_a)
      backlogs_page.apply_bucket_filter(bucket_a)

      backlogs_page.clear_filter(:sprint)

      backlogs_page.expect_sprint(sprint_a)
      backlogs_page.expect_sprint(sprint_b)
      backlogs_page.expect_backlog_bucket(bucket_a)
      backlogs_page.expect_no_backlog_bucket(bucket_b)
    end

    it "clears the bucket filter while preserving the sprint filter and restoring the inbox" do
      backlogs_page.apply_sprint_filter(sprint_a)
      backlogs_page.apply_bucket_filter(bucket_a)
      backlogs_page.expect_no_inbox

      backlogs_page.clear_filter(:backlog_bucket)

      backlogs_page.expect_sprint(sprint_a)
      backlogs_page.expect_no_sprint(sprint_b)
      backlogs_page.expect_backlog_bucket(bucket_a)
      backlogs_page.expect_backlog_bucket(bucket_b)
      backlogs_page.expect_inbox
    end
  end

  describe "filter counter" do
    it "shows no counter when no filter is active and the count when items are selected" do
      backlogs_page.expect_no_filter_count(:sprint)
      backlogs_page.expect_no_filter_count(:backlog_bucket)

      backlogs_page.apply_sprint_filter(sprint_a)
      backlogs_page.expect_filter_count(:sprint, 1)

      backlogs_page.apply_sprint_filter(sprint_b)
      backlogs_page.expect_filter_count(:sprint, 2)

      backlogs_page.apply_bucket_filter(bucket_a)
      backlogs_page.expect_filter_count(:backlog_bucket, 1)
    end
  end

  context "when executing various actions on the page" do
    context "with sprint_a and bucket_a selected" do
      before do
        backlogs_page.apply_sprint_filter(sprint_a)
        backlogs_page.apply_bucket_filter(bucket_a, include_inbox: true)
      end

      def expect_selected_filters_preserved
        backlogs_page.expect_sprint(sprint_a)
        backlogs_page.expect_no_sprint(sprint_b)
        backlogs_page.expect_backlog_bucket(bucket_a)
        backlogs_page.expect_no_backlog_bucket(bucket_b)
      end

      it "preserves the filter after sprint and bucket CRUD actions" do
        backlogs_page.click_in_sprint_menu(sprint_a, "Edit sprint")
        within_dialog "Edit sprint" do
          fill_in "Sprint name", with: "Sprint A Renamed"
          click_on "Save"
        end
        expect_and_dismiss_flash type: :success
        expect_selected_filters_preserved

        backlogs_page.open_create_sprint_dialog
        within_dialog "New sprint" do
          fill_in "Sprint name", with: "Sprint C"
          fill_in "Start date", with: "2025-11-01"
          fill_in "Finish date", with: "2025-11-14"
          click_on "Create"
        end
        expect_and_dismiss_flash type: :success
        backlogs_page.expect_no_sprint(Sprint.find_by!(project:, name: "Sprint C"))
        expect_selected_filters_preserved

        backlogs_page.click_in_backlog_bucket_menu(bucket_a, "Edit backlog bucket")
        within_dialog "Edit backlog bucket" do
          fill_in "Name", with: "Bucket A Renamed"
          click_on "Save"
        end
        expect_and_dismiss_flash type: :success
        expect_selected_filters_preserved

        backlogs_page.open_create_bucket_dialog
        within_dialog "New backlog bucket" do
          fill_in "Name", with: "Bucket C"
          click_on "Create"
        end
        expect_and_dismiss_flash type: :success
        backlogs_page.expect_no_backlog_bucket(BacklogBucket.find_by!(project:, name: "Bucket C"))
        expect_selected_filters_preserved
      end

      it "preserves the filter after drag and drop" do
        backlogs_page.drag_work_package_to_backlog_inbox(sprint_a_wp)
        expect_selected_filters_preserved

        backlogs_page.drag_work_package_to_backlog_bucket(sprint_a_wp, bucket_a)
        expect_selected_filters_preserved

        backlogs_page.drag_work_package_to_sprint(bucket_a_wp, sprint_a)
        expect_selected_filters_preserved
      end

      it "preserves the filter after moving work packages via the action menu" do
        backlogs_page.click_in_work_package_menu(sprint_a_wp, "Move to backlog inbox")
        expect_selected_filters_preserved
        backlogs_page.expect_inbox_item(sprint_a_wp)

        backlogs_page.click_in_work_package_menu(sprint_a_wp, "Move to backlog bucket")
        within_modal "Move to backlog bucket" do
          select bucket_a.name, from: "target_id"
          click_on "Move"
        end
        wait_for_network_idle
        expect_selected_filters_preserved
        backlogs_page.expect_work_package_in_backlog_bucket(sprint_a_wp, bucket_a)

        backlogs_page.click_in_work_package_menu(bucket_a_wp, "Move to sprint")
        within_modal "Move to sprint" do
          select sprint_a.name, from: "target_id"
          click_on "Move"
        end
        wait_for_network_idle
        expect_selected_filters_preserved
        backlogs_page.expect_work_package_in_sprint(bucket_a_wp, sprint_a)
      end
    end
  end
end
