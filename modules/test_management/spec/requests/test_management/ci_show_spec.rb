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

RSpec.describe "Test management CI page", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs manage_test_ci] })
  end

  let(:path) { project_test_management_ci_path(project) }

  before { login_as(user) }

  it "lists the active connections and only automation runs, newest first" do
    active = create(:tm_ci_connection, project:)
    inactive = create(:tm_ci_connection, project:, active: false)
    older = create(:tm_test_run, :automation, project:)
    newer = create(:tm_test_run, :automation, project:)
    manual = create(:tm_test_run, project:)

    get path

    expect(response).to have_http_status(:ok)
    page = Capybara.string(response.body)
    expect(page).to have_css("[data-test-selector='tm-ci-connection-#{active.id}']")
    expect(page).to have_no_css("[data-test-selector='tm-ci-connection-#{inactive.id}']")
    expect(page).to have_no_css("[data-test-selector='tm-ci-run-#{manual.id}']")
    ids = page.all("[data-test-selector^='tm-ci-run-']").pluck("data-test-selector")
    expect(ids).to eq(["tm-ci-run-#{newer.id}", "tm-ci-run-#{older.id}"])
  end

  it "shows at most the recent runs" do
    stub_const("TestManagement::CiController::RECENT_RUNS", 2)
    create_list(:tm_test_run, 3, :automation, project:)

    get path

    expect(Capybara.string(response.body)).to have_css("[data-test-selector^='tm-ci-run-']", count: 2)
  end

  it "shows the empty state without automation runs" do
    create(:tm_test_run, project:)

    get path

    expect(Capybara.string(response.body)).to have_css("[data-test-selector='tm-ci-no-runs']")
  end

  it "is forbidden while CI is switched off" do
    create(:tm_project_setting, project:, options: { "enable_ci" => false })

    get path

    expect(response).to have_http_status(:forbidden)
  end
end
