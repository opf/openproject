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

RSpec.describe SquashTMIntegration::WorkPackageSquashTMTabComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:status) { :not_linked }
  let(:can_configure_server) { false }
  let(:can_manage_links) { false }
  let(:server) { build_stubbed(:squashtm_server) }
  let(:requirement) { nil }
  let(:requirement_error) { nil }
  let(:can_manage_project_link) { false }
  let(:work_package_link) { SquashTMIntegration::WorkPackageLink.new(work_package:) }
  let(:tab_state) do
    instance_double(SquashTMIntegration::WorkPackageTabState,
                    work_package:,
                    project:,
                    status:,
                    work_package_link:,
                    server:,
                    requirement:,
                    requirement_error:,
                    requirement_options: [{ id: 1, name: "Users can sign in" }],
                    can_configure_server?: can_configure_server,
                    can_manage_links?: can_manage_links,
                    can_manage_project_link?: can_manage_project_link)
  end

  current_user { build_stubbed(:user) }

  subject(:render_component) { render_inline(described_class.new(tab_state)) }

  it "renders the empty state inside the tab turbo frame" do
    render_component

    expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
    expect(page).to have_text("No SquashTM requirement linked")
    expect(page).to have_no_field("SquashTM requirement")
  end

  context "for a user allowed to manage links" do
    let(:can_manage_links) { true }

    it "offers the requirements of the linked SquashTM project" do
      render_component

      expect(page).to have_select("SquashTM requirement", with_options: ["Users can sign in"])
      expect(page).to have_button("Link requirement")
    end

    context "when the requirements could not be loaded" do
      let(:tab_state) do
        instance_double(SquashTMIntegration::WorkPackageTabState,
                        work_package:, project:, status:, work_package_link:,
                        requirement_options: nil, can_manage_links?: true, can_manage_project_link?: false)
      end

      it "explains that SquashTM is not reachable" do
        render_component

        expect(page).to have_text("The SquashTM requirements could not be loaded")
        expect(page).to have_no_button("Link requirement")
      end
    end
  end

  context "when a requirement is linked" do
    let(:status) { :linked }
    let(:work_package_link) do
      build_stubbed(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 11,
                                                 squashtm_requirement_name: "Users can sign in")
    end
    let(:test_cases) do
      [
        SquashTMIntegration::RequirementCoverage::TestCase.new(
          id: 21, name: "Valid login", reference: "TC-001", description: nil, execution_status: "SUCCESS",
          last_executed_on: Time.zone.parse("2026-10-24 10:00"), last_executed_by: "bob"
        ),
        SquashTMIntegration::RequirementCoverage::TestCase.new(
          id: 22, name: "Wrong password", reference: nil, description: nil, execution_status: nil,
          last_executed_on: nil, last_executed_by: nil
        )
      ]
    end
    let(:requirement) do
      SquashTMIntegration::RequirementCoverage::Requirement.new(
        id: 11, name: "Users can sign in", reference: "REQ-001", status: "APPROVED", test_cases:
      )
    end

    it "shows the requirement with a link to SquashTM" do
      render_component

      expect(page).to have_text("REQ-001")
      expect(page).to have_text("Approved")
      expect(page).to have_link("Users can sign in", href: %r{/requirement-workspace/requirement-library/11/content})
    end

    it "lists the test cases with their latest execution status" do
      render_component

      expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-21']", text: "Passed")
      expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-21']", text: "by bob")
      expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--test-case-22']", text: "Not executed")
    end

    it "offers no unlink action without the permission" do
      render_component

      expect(page).to have_no_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
    end

    context "for a user allowed to manage links" do
      let(:can_manage_links) { true }

      it "offers to unlink the requirement" do
        render_component

        expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--unlink']")
      end
    end

    context "when the requirement has no test cases" do
      let(:test_cases) { [] }

      it "shows an empty state" do
        render_component

        expect(page).to have_text("No test cases")
      end
    end

    context "when the requirement no longer exists in SquashTM" do
      let(:requirement) { nil }
      let(:requirement_error) { :not_found }

      it "warns and keeps showing the cached name" do
        render_component

        expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--requirement-missing']")
        expect(page).to have_text("Users can sign in")
      end
    end

    context "when SquashTM is not reachable" do
      let(:requirement) { nil }
      let(:requirement_error) { :unavailable }

      it "explains that the test cases could not be loaded" do
        render_component

        expect(page).to have_css("[data-test-selector='op-work-package-squashtm-tab--unavailable']")
        expect(page).to have_text("Users can sign in")
      end
    end
  end

  context "when the project is not linked to a SquashTM project" do
    let(:status) { :project_not_linked }

    it "asks the user to contact a project administrator" do
      render_component

      expect(page).to have_text("No SquashTM project linked")
      expect(page).to have_text("Please contact a project administrator")
      expect(page).to have_no_link("Link SquashTM project")
    end

    context "for a user allowed to manage the integration" do
      let(:can_manage_project_link) { true }

      it "links to the project settings, leaving the tab frame" do
        render_component

        expect(page).to have_css("a[data-turbo-frame='_top']", text: "Link SquashTM project")
      end
    end
  end

  context "without a configured server" do
    let(:status) { :no_server }

    it "asks the user to contact the instance administrator" do
      render_component

      expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
      expect(page).to have_text("SquashTM is not available")
      expect(page).to have_text("Please contact your instance administrator")
      expect(page).to have_no_link("Configure SquashTM")
    end

    context "for an administrator" do
      let(:can_configure_server) { true }

      it "links to the SquashTM administration, leaving the tab frame" do
        render_component

        expect(page).to have_no_text("Please contact your instance administrator")
        expect(page).to have_link("Configure SquashTM", href: "/squashtm_integration/admin/server")
        expect(page).to have_css("a[data-turbo-frame='_top']", text: "Configure SquashTM")
      end
    end
  end
end
