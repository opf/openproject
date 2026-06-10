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

RSpec.describe "Backlog pagination state", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end
  shared_let(:inbox_work_packages) { create_list(:work_package, 6, project:, sprint: nil) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { create(:admin) }

  before do
    # Stub the threshold so only 6 work packages are needed to trigger pagination.
    # The inbox derives tail = max(truncate_middle / 5, 1) and the truncation
    # threshold as truncate_middle + tail*2 = 5; 6 > 5 triggers the show-more row.
    stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 3)

    backlogs_page.visit!
    backlogs_page.expect_inbox_show_more
    backlogs_page.click_inbox_show_more
    backlogs_page.expect_no_inbox_show_more
  end

  it "preserves the expanded backlog state after sprint and backlog bucket actions" do
    # Create sprint
    backlogs_page.open_create_sprint_dialog

    within_dialog "New sprint" do
      fill_in "Sprint name", with: "My sprint"
      fill_in "Start date", with: "2025-10-05"
      fill_in "Finish date", with: "2025-10-20"
      click_on "Create"
    end

    expect_and_dismiss_flash type: :success, exact_message: "Successful creation."
    backlogs_page.expect_no_inbox_show_more

    # Create backlog bucket
    backlogs_page.open_create_bucket_dialog

    within_dialog "New backlog bucket" do
      fill_in "Name", with: "New bucket"
      click_on "Create"
    end

    expect_and_dismiss_flash type: :success, exact_message: "Successful creation."
    backlogs_page.expect_no_inbox_show_more

    bucket = BacklogBucket.find_by!(project:, name: "New bucket")

    # Edit backlog bucket
    backlogs_page.click_in_backlog_bucket_menu(bucket, "Edit backlog bucket")

    within_dialog "Edit backlog bucket" do
      fill_in "Name", with: "Renamed bucket"
      click_on "Save"
    end

    expect_and_dismiss_flash type: :success, exact_message: "Successful update."
    backlogs_page.expect_no_inbox_show_more

    # Delete backlog bucket
    backlogs_page.click_in_backlog_bucket_menu(bucket, "Delete backlog bucket")

    backlogs_page.expect_and_confirm_backlog_bucket_delete_modal

    expect_and_dismiss_flash type: :success, exact_message: "Successful deletion."
    backlogs_page.expect_no_inbox_show_more
  end
end
