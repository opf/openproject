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

RSpec.describe "Update run case status", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs execute_test_runs]
           })
  end
  shared_let(:run) { create(:tm_test_run, project:) }
  shared_let(:run_case) { create(:tm_test_run_case, test_run: run, status: "untested") }

  current_user { user }

  it "sets a status from the run show page" do
    visit project_test_management_test_run_path(project, run)

    expect(page).to have_css("[data-test-selector='tm-run-case-#{run_case.id}']")

    within("[data-test-selector='tm-run-case-status-#{run_case.id}']") do
      click_button
    end
    find(:xpath, ".//form[input[@name='run_case[status]' and @value='passed']]//button").click

    expect(page).to have_css("[data-test-selector='tm-run-case-status-#{run_case.id}'] .tm-run-status--passed", wait: 10)
    expect(run_case.reload.status).to eq("passed")
  end
end
