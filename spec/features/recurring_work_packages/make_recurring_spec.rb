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

RSpec.describe "Making a work package recurring", :js do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:default_status) { create(:default_status, name: "New") }
  shared_let(:closed_status) { create(:closed_status, name: "Closed") }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages edit_work_packages add_work_package_notes
                           view_recurring_work_packages manage_recurring_work_packages])
  end
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }
  shared_let(:workflow) do
    create(:status_transition, type:, role:, old_status: default_status, new_status: closed_status)
  end
  shared_let(:work_package) do
    create(:work_package,
           project:,
           type:,
           author: user,
           status: default_status,
           subject: "Check the backups",
           start_date: Date.new(2026, 10, 5),
           due_date: Date.new(2026, 10, 6))
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:dialog_id) { RecurringWorkPackages::DialogComponent::DIALOG_ID }

  before do
    login_as(user)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "creates the next occurrence when the work package closes, and on demand" do
    click_link_or_button "More"
    click_link_or_button "Make recurring"

    within("##{dialog_id}") do
      expect(page).to have_field "Repeats", with: "weekly"
      expect(page).to have_field "First occurrence", with: "2026-10-05"
      expect(page).to have_no_field "Occurrences"

      select "After a number of occurrences", from: "Ends"
      fill_in "Occurrences", with: "3"

      click_button "Make recurring"
    end

    expect(page).to have_no_css("##{dialog_id}")
    expect_flash(message: "This work package now recurs: Every week on Monday, 3 times.")
    expect(page).to have_test_selector("op-wp-recurrence", text: "Every week on Monday · 1 of 3")

    perform_enqueued_jobs do
      wp_page.fill_in_attributes status: "Closed"
      wp_page.expect_attributes status: "Closed"
    end

    visit project_recurring_work_packages_path(project)
    expect(page).to have_test_selector("recurring-series-list", text: "Every week on Monday, 3 times")
    click_link_or_button "Check the backups"

    expect(page).to have_text "Every week on Monday, 3 times"
    expect(page).to have_test_selector("recurring-occurrence-1", text: "Closed")
    expect(page).to have_test_selector("recurring-occurrence-2", text: "Check the backups")
    expect(page).to have_test_selector("recurring-occurrence-2", text: "New")
    expect(page).to have_test_selector("recurring-planned", count: 1)

    click_link_or_button "Create next now"

    expect(page).to have_test_selector("recurring-occurrence-3", text: "Check the backups")
    expect(page).to have_no_test_selector("recurring-planned")
    expect(page).to have_text "This recurrence has ended."
    expect(page).to have_no_link "Create next now"
  end
end
