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
require_relative "../../support/pages/projects/settings/backlogs"

RSpec.describe "Backlogs settings effect on backlog and sprints", :js do
  let!(:done_like_status) { create(:status, name: "Done-like status", is_closed: false) }
  let!(:in_progress_status) { create(:status, name: "In progress", is_closed: false) }

  let!(:included_type) { create(:type_feature, name: "Story") }
  let!(:excluded_type) { create(:type_task, name: "Chore") }

  let!(:project) do
    create(:project,
           enabled_module_names: %i[backlogs work_package_tracking board_view],
           types: [included_type, excluded_type])
  end

  let(:permissions) do
    %i[view_sprints add_work_packages view_work_packages create_sprints manage_sprint_items
       start_complete_sprint select_backlog_types_and_statuses]
  end

  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  let(:settings_page) { Pages::Projects::Settings::Backlogs.new(project) }
  let(:backlog_page) { Pages::Backlog.new(project) }

  let(:done_status_ids_autocompleter) do
    FormFields::Primerized::AutocompleteField.new(
      "done_status_ids",
      selector: "[data-test-selector='done_status_ids_autocomplete']"
    )
  end

  let(:backlog_excluded_type_ids_autocompleter) do
    FormFields::Primerized::AutocompleteField.new(
      "backlog_excluded_type_ids",
      selector: "[data-test-selector='backlog_excluded_type_ids_autocomplete']"
    )
  end

  let!(:active_sprint) do
    create(:sprint,
           project:,
           status: "active",
           start_date: Date.new(2025, 10, 5),
           finish_date: Date.new(2025, 10, 15))
  end

  let!(:inbox_hidden_by_done_status) do
    create(:work_package,
           project:,
           sprint: nil,
           status: done_like_status,
           type: included_type,
           subject: "Inbox hidden by done status")
  end

  let!(:inbox_hidden_by_excluded_type) do
    create(:work_package,
           project:,
           sprint: nil,
           status: in_progress_status,
           type: excluded_type,
           subject: "Inbox hidden by excluded type")
  end

  let!(:inbox_visible_work_package) do
    create(:work_package,
           project:,
           sprint: nil,
           status: in_progress_status,
           type: included_type,
           subject: "Inbox visible work package")
  end

  let!(:sprint_done_work_package) do
    create(:work_package,
           project:,
           sprint: active_sprint,
           status: done_like_status,
           type: included_type,
           subject: "Sprint done-like work package")
  end

  let!(:sprint_excluded_type_work_package) do
    create(:work_package,
           project:,
           sprint: active_sprint,
           status: in_progress_status,
           type: excluded_type,
           subject: "Sprint excluded type work package")
  end

  let!(:sprint_visible_work_package) do
    create(:work_package,
           project:,
           sprint: active_sprint,
           status: in_progress_status,
           type: included_type,
           subject: "Sprint visible work package")
  end

  before do
    login_as(user)

    configure_backlogs_settings
  end

  it "filters the backlog inbox and keeps sprint cards visible while sprint is active" do
    backlog_page.visit!

    expect_inbox_filtering
    expect_sprint_items_unaffected
  end

  it "applies done and excluded settings to items moved from a completed sprint" do
    backlog_page.visit!

    expect_sprint_items_unaffected

    backlog_page.click_to_complete_sprint(active_sprint)
    backlog_page.expect_sprint_completing_modal
    backlog_page.choose_to_move_unfinished_work_packages_to_top_of_backlog

    backlog_page.expect_and_dismiss_flash type: :success, message: "The sprint was completed."

    # Done-like status marks this as finished and therefore not moved to backlog.
    backlog_page.expect_no_inbox_item(sprint_done_work_package)

    # Excluded types are moved to backlog but still hidden from inbox by settings.
    # TODO: add assertion for flash message once it's in
    backlog_page.expect_no_inbox_item(sprint_excluded_type_work_package)

    # Regular unfinished work packages are moved to and shown in the inbox.
    backlog_page.expect_inbox_item(sprint_visible_work_package)
    backlog_page.expect_inbox_item(inbox_visible_work_package)
  end

  private

  def configure_backlogs_settings
    settings_page.visit!

    wait_for_network_idle
    wait_for_autocompleter_options_to_be_loaded

    done_status_ids_autocompleter.select_option(done_like_status.name)
    backlog_excluded_type_ids_autocompleter.select_option(excluded_type.name)

    done_status_ids_autocompleter.close_autocompleter
    backlog_excluded_type_ids_autocompleter.close_autocompleter

    click_button "Save"

    expect_flash(type: :success, message: "Successful update")
  end

  def expect_inbox_filtering
    backlog_page.expect_no_inbox_item(inbox_hidden_by_done_status)
    backlog_page.expect_no_inbox_item(inbox_hidden_by_excluded_type)
    backlog_page.expect_inbox_item(inbox_visible_work_package)
  end

  def expect_sprint_items_unaffected
    backlog_page.expect_work_package_in_sprint(sprint_done_work_package, active_sprint)
    backlog_page.expect_work_package_in_sprint(sprint_excluded_type_work_package, active_sprint)
    backlog_page.expect_work_package_in_sprint(sprint_visible_work_package, active_sprint)
  end
end
