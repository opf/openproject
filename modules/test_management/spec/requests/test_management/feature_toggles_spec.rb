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

RSpec.describe "Test management feature toggles (CI)", :disable_ssrf_filter, :skip_csrf, :webmock, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs manage_test_ci trigger_test_automation
                           manage_test_management]
           })
  end
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

  let(:base) { "/projects/#{project.identifier}/test_management" }
  let(:ci_enabled) { true }

  before do
    create(:tm_project_setting, project:, options: { "enable_ci" => ci_enabled })
    login_as(user)
  end

  def page = Capybara.string(response.body)

  def trigger
    stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_return(status: 204)
    post "#{base}/ci_triggers", params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id } }
  end

  context "with enable_ci on" do
    it "shows the CI section, the CI page and the trigger buttons" do
      get "#{base}/project_settings"
      expect(page).to have_css("[data-test-selector='tm-ci-connections']")

      get "#{base}/ci"
      expect(response).to have_http_status(:ok)

      get "#{base}/test_cases/#{automated.id}"
      expect(page).to have_css("[data-test-selector='tm-case-ci-trigger']")

      get "#{base}/test_cases", params: { suite_id: suite.id }
      expect(page).to have_css("[data-test-selector='tm-folder-ci-trigger']")
    end

    it "triggers a run" do
      trigger

      expect(response).to have_http_status(:see_other)
      expect(TestManagement::TestRun.where(project_id: project.id).count).to eq(1)
    end
  end

  context "with enable_ci off" do
    let(:ci_enabled) { false }

    it "hides the CI section on the project settings page" do
      get "#{base}/project_settings"

      expect(response).to have_http_status(:ok)
      expect(page).to have_no_css("[data-test-selector='tm-ci-connections']")
      expect(page).to have_css("[data-test-selector='tm-enable-ci']")
    end

    it "refuses the CI page and the trigger" do
      get "#{base}/ci"
      expect(response).to have_http_status(:forbidden)

      get "#{base}/ci_triggers/new", params: { suite_id: suite.id }
      expect(response).to have_http_status(:forbidden)

      trigger
      expect(response).to have_http_status(:forbidden)
      expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
    end

    it "hides the trigger button on a case" do
      get "#{base}/test_cases/#{automated.id}"

      expect(page).to have_no_css("[data-test-selector='tm-case-ci-trigger']")
    end

    it "hides the trigger button on a folder" do
      get "#{base}/test_cases", params: { suite_id: suite.id }

      expect(page).to have_no_css("[data-test-selector='tm-folder-ci-trigger']")
    end
  end

  it "can be switched off from the project settings form" do
    patch "#{base}/project_settings", params: { project_setting: { enable_ci: "0" } }

    expect(TestManagement::ProjectSetting.enabled?(project, :ci)).to be(false)

    patch "#{base}/project_settings", params: { project_setting: { enable_ci: "1" } }

    expect(TestManagement::ProjectSetting.enabled?(project, :ci)).to be(true)
  end
end
