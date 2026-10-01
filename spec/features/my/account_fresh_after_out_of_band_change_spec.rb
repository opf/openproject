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

# After an administrator changes a user's attributes out-of-band (e.g. their department,
# or the "Job title" custom field), the account page must not keep showing the old values.
# The examples below cover each way of returning to the page.
RSpec.describe "My account is never served stale after an out-of-band change", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section, name: "Professional info") }
  shared_let(:job_title) { create(:user_custom_field, :string, name: "Job title", user_custom_field_section: section) }
  shared_let(:alpha) { create(:department, name: "Alpha department", members: [admin]) }
  shared_let(:beta) { create(:department, name: "Beta department") }

  before do
    section.update!(attribute_order: ["department", job_title.column_name])
    admin.update!(custom_field_values: { job_title.id => "Old title" })
    login_as admin
    visit my_account_path
  end

  # Confirms the page rendered the current values, then has an administrator change the
  # department and job title out-of-band so that any browser/Turbo cache now holds stale data.
  def change_department_and_job_title_out_of_band
    expect(page).to have_select("user[department_id]", disabled: true, selected: "Alpha department")
    expect(page).to have_field("Job title", with: "Old title")

    Departments::AddUserService.new(beta, user: admin)
                               .call(user_id: admin.id, remove_from_previous_department: true)
    admin.update!(custom_field_values: { job_title.id => "New title" })
  end

  def expect_fresh_account
    expect(page).to have_select("user[department_id]", disabled: true, selected: "Beta department")
    expect(page).to have_field("Job title", with: "New title")
  end

  # Fixed by the `turbo-cache-control: no-cache` meta: a restoration visit would
  # otherwise re-render Turbo's cached snapshot.
  it "is fresh after navigating away and back through browser history" do
    change_department_and_job_title_out_of_band

    click_on "Notification and email"
    expect(page).to have_current_path(my_notifications_path, wait: 10, ignore_query: true)

    page.go_back

    expect_fresh_account
  end

  # Green in Chrome (it revalidates on reload) but stale in Firefox, where the HTTP
  # cache / bfcache serves the old page; fixed by `Cache-Control: no-store`.
  it "is fresh after a reload" do
    change_department_and_job_title_out_of_band

    page.refresh

    expect_fresh_account
  end

  # Navigating back to the account page through the menu is a fresh Turbo visit;
  # this guards that it keeps fetching current data.
  it "is fresh after navigating away and back via the menu" do
    change_department_and_job_title_out_of_band

    click_on "Notification and email"
    expect(page).to have_current_path(my_notifications_path, wait: 10, ignore_query: true)

    click_on "Account"
    expect(page).to have_current_path(my_account_path, wait: 10, ignore_query: true)

    expect_fresh_account
  end
end
