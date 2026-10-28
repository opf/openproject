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

RSpec.describe "Work package SquashTM tab",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_squashtm_test_results] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:client) { instance_double(SquashTMIntegration::Client) }
  let(:requirement) do
    {
      "id" => 11,
      "name" => "Users can sign in",
      "project" => { "id" => 1 },
      "current_version" => {
        "name" => "Users can sign in",
        "reference" => "REQ-001",
        "status" => "APPROVED",
        "verifying_test_cases" => [{ "id" => 21, "name" => "Valid login" }, { "id" => 22, "name" => "Wrong password" }]
      }
    }
  end

  subject do
    get "/projects/#{project.id}/work_packages/#{work_package.id}/squashtm/tab"
    response
  end

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive_messages(requirement:,
                                      all_requirements: [{ "id" => 11, "name" => "Users can sign in" }])
    allow(client).to receive(:test_case_executions).with(21).and_return(
      [
        { "execution_status" => "FAILURE", "last_executed_on" => "2026-10-20T10:00:00.000Z", "last_executed_by" => "alice" },
        { "execution_status" => "SUCCESS", "last_executed_on" => "2026-10-24T10:00:00.000Z", "last_executed_by" => "bob" },
        { "execution_status" => "READY", "last_executed_on" => nil, "last_executed_by" => nil }
      ]
    )
    allow(client).to receive(:test_case_executions).with(22).and_return([])
    allow(client).to receive(:test_case).with(21).and_return(
      { "id" => 21, "name" => "Valid login", "reference" => "TC-001",
        "description" => "<p>Signs in with <strong>valid</strong> credentials.</p><script>alert(1)</script>" }
    )
    allow(client).to receive(:test_case).with(22).and_return({ "id" => 22, "name" => "Wrong password", "reference" => "TC-002" })
    login_as user
  end

  it "tells the user when no SquashTM server is configured" do
    expect(subject).to have_http_status(:ok)
    expect(subject.body).to include("work-package-squashtm-tab-content")
    expect(subject.body).to include("SquashTM is not available")
    expect(SquashTMIntegration::Client).not_to have_received(:for)
  end

  context "with a configured server" do
    before { create(:squashtm_server) }

    it "tells the user when the project is not linked to a SquashTM project" do
      expect(subject).to have_http_status(:ok)
      expect(subject.body).to include("No SquashTM project linked")
    end

    context "and a linked project" do
      before { create(:squashtm_project_link, project:, squashtm_project_id: 1) }

      it "shows that no requirement is linked yet" do
        expect(subject.body).to include("No SquashTM requirement linked")
        expect(subject.body).not_to include("Link requirement")
      end

      context "for a user allowed to manage links" do
        let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }

        it "offers the requirements to link" do
          expect(subject.body).to include("Link requirement", "Users can sign in")
        end
      end

      context "and a linked requirement" do
        before do
          create(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 11)
        end

        it "lists the test cases with their latest execution status" do
          expect(subject).to have_http_status(:ok)
          page = Capybara.string(subject.body)

          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--requirement']",
                                   text: /REQ-001\s+#11\s+Approved\s+Users can sign in/)
          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-21']", text: "Passed")
          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-21']", text: "by bob")
          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-21']", text: "TC-001")
          expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-22']", text: "Not executed")
          expect(page).to have_css("#squashtm_test_cases", text: "Test cases")
          expect(page).to have_no_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
        end

        it "links the requirement and the test cases to SquashTM" do
          page = Capybara.string(subject.body)

          expect(page).to have_link(
            "Users can sign in",
            href: "https://squashtm.example.com/squash/requirement-workspace/requirement-library/11/content?anchor=dashboard"
          )
          expect(page).to have_link(
            "Valid login",
            href: "https://squashtm.example.com/squash/test-case-workspace/test-case/21/content?anchor=information"
          )
          expect(page).to have_css("a[target='_blank'][rel='noopener noreferrer']", text: "Valid login")
        end

        it "shows the sanitized test case description" do
          description = Capybara.string(subject.body)
                                .find("[data-test-selector='op-work-package-squashtm-tab--test-case-description']")

          expect(description).to have_css("strong", text: "valid")
          expect(description).to have_no_css("script")
          expect(subject.body).not_to include("<script")
        end

        it "warns when the requirement no longer exists in SquashTM" do
          allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError)

          expect(subject.body).to include("The linked SquashTM requirement is no longer visible in SquashTM.")
          expect(subject.body).to include("Users can sign in")
        end

        it "explains when SquashTM is not reachable" do
          allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::SsrfError)

          expect(subject).to have_http_status(:ok)
          expect(subject.body).to include("The test cases could not be loaded")
        end

        context "for a user allowed to manage links" do
          let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }

          it "offers to unlink the requirement" do
            expect(Capybara.string(subject.body)).to have_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
          end
        end
      end
    end
  end

  context "without the permission to view SquashTM test results" do
    let(:permissions) { %i[view_work_packages] }

    it { is_expected.to have_http_status(:forbidden) }
  end

  context "when the SquashTM project module is disabled" do
    before do
      project.enabled_module_names = %i[work_package_tracking]
    end

    it { is_expected.to have_http_status(:forbidden) }
  end
end
