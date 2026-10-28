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

require "spec_helper"

RSpec.describe "SquashTM tab on work packages", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:, subject: "Sign in screen") }

  let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_links] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions }, preferences: { warn_on_leaving_unsaved: false })
  end
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
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

  before do
    allow(SquashTMIntegration::Client).to receive(:for).and_return(client)
    allow(client).to receive_messages(
      requirement:,
      all_requirements: [{ "id" => 11, "name" => "Users can sign in", "current_version" => { "reference" => "REQ-001" } }],
      all_projects: [{ "id" => 1, "name" => "Integration Sandbox" }]
    )
    allow(client).to receive(:test_case).with(21).and_return({ "id" => 21, "name" => "Valid login", "reference" => "TC-001" })
    allow(client).to receive(:test_case).with(22).and_return({ "id" => 22, "name" => "Wrong password" })
    allow(client).to receive(:test_case_executions).with(21).and_return(
      [{ "execution_status" => "SUCCESS", "last_executed_on" => "2026-10-24T10:00:00.000Z", "last_executed_by" => "bob" }]
    )
    allow(client).to receive(:test_case_executions).with(22).and_return([])

    login_as(user)
    work_package_page.visit!
  end

  context "without a configured SquashTM server" do
    it "tells the user to contact the instance administrator" do
      work_package_page.switch_to_tab(tab: "squashtm")

      expect(page).to have_text("SquashTM is not available")
      expect(page).to have_text("Please contact your instance administrator")
      expect(page).to have_no_link("Configure SquashTM")
    end

    context "for an administrator" do
      let(:user) { create(:admin, preferences: { warn_on_leaving_unsaved: false }) }

      it "links to the SquashTM administration" do
        work_package_page.switch_to_tab(tab: "squashtm")

        click_link "Configure SquashTM"

        expect(page).to have_current_path("/squashtm_integration/admin/server")
      end
    end
  end

  context "with a configured server" do
    before { create(:squashtm_server) }

    context "when the project is not linked to a SquashTM project" do
      it "tells the user to contact a project administrator" do
        work_package_page.switch_to_tab(tab: "squashtm")

        expect(page).to have_text("No SquashTM project linked")
        expect(page).to have_text("Please contact a project administrator")
      end

      context "for a user allowed to manage the integration" do
        let(:permissions) { %i[view_work_packages view_squashtm_test_results manage_squashtm_integration] }

        it "links to the project settings" do
          work_package_page.switch_to_tab(tab: "squashtm")

          click_link "Link SquashTM project"

          expect(page).to have_current_path("/projects/#{project.identifier}/settings/squashtm")
        end
      end
    end

    context "when the project is linked to a SquashTM project" do
      before { create(:squashtm_project_link, project:, squashtm_project_id: 1) }

      it "links a requirement, shows its test cases and unlinks it again" do
        work_package_page.switch_to_tab(tab: "squashtm")
        expect(page).to have_text("No SquashTM requirement linked")

        select "REQ-001 – Users can sign in", from: "SquashTM requirement"
        click_button "Link requirement"

        within_test_selector("op-work-package-squashtm-tab--requirement") do
          expect(page).to have_text("REQ-001")
          expect(page).to have_text("Approved")
          expect(page).to have_link("Users can sign in")
        end
        within_test_selector("op-work-package-squashtm-tab--test-case-21") do
          expect(page).to have_text("Valid login")
          expect(page).to have_text("Passed")
          expect(page).to have_text("bob")
        end
        within_test_selector("op-work-package-squashtm-tab--test-case-22") do
          expect(page).to have_text("Not executed")
        end

        within_test_selector("op-work-package-squashtm-tab--requirement-menu") do
          click_button accessible_name: "Actions"
        end
        click_link_or_button "Unlink"
        within_test_selector("op-work-package-squashtm-tab--unlink-dialog") do
          expect(page).to have_text("Unlink the SquashTM requirement Users can sign in?")
          click_button "Unlink"
        end

        expect(page).to have_text("No SquashTM requirement linked")
        expect(SquashTMIntegration::WorkPackageLink).not_to exist
      end

      it "shows the error when the requirement cannot be linked" do
        allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError)
        work_package_page.switch_to_tab(tab: "squashtm")

        select "REQ-001 – Users can sign in", from: "SquashTM requirement"
        click_button "Link requirement"

        expect(page).to have_text("does not exist or is not visible to the SquashTM account")
        expect(SquashTMIntegration::WorkPackageLink).not_to exist
      end

      context "without the permission to manage requirement links" do
        let(:permissions) { %i[view_work_packages view_squashtm_test_results] }

        before { create(:squashtm_work_package_link, work_package:) }

        it "shows the requirement without a way to unlink it" do
          work_package_page.switch_to_tab(tab: "squashtm")

          expect(page).to have_test_selector("op-work-package-squashtm-tab--requirement")
          expect(page).to have_no_test_selector("op-work-package-squashtm-tab--requirement-menu")
        end
      end
    end
  end

  context "in the split view" do
    let(:work_package_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }

    before { create(:squashtm_server) }

    it "shows the tab" do
      work_package_page.switch_to_tab(tab: "squashtm")

      expect(page).to have_text("No SquashTM project linked")
    end
  end

  context "without the permission to view SquashTM test results" do
    let(:permissions) { %i[view_work_packages] }

    it "does not show the tab" do
      work_package_page.expect_no_tab("squashtm")
    end
  end
end
