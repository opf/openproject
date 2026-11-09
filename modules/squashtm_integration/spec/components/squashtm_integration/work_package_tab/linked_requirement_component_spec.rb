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

RSpec.describe SquashTMIntegration::WorkPackageTab::LinkedRequirementComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:can_manage_links) { false }
  let(:work_package_link) do
    build_stubbed(:squashtm_work_package_link, work_package:, squashtm_requirement_id: 11,
                                               squashtm_requirement_name: "Users can sign in")
  end
  let(:error) { nil }
  let(:view_model) do
    instance_double(SquashTMIntegration::WorkPackageSquashTMTabViewModel,
                    work_package:, project:, work_package_link:, client: SquashTMIntegration::Client.for(build_stubbed(:squashtm_server)),
                    can_manage_links?: can_manage_links)
  end
  let(:linked_requirement) do
    SquashTMIntegration::RequirementLoader::LinkedRequirement.new(requirement:, error:)
  end
  let(:test_cases) do
    [
      SquashTMIntegration::RequirementLoader::TestCase.new(
        id: 21, name: "Valid login", reference: "TC-001", description: nil, execution_status: "SUCCESS",
        last_executed_on: Time.zone.parse("2026-10-24 10:00"), last_executed_by: "bob",
        url: "https://squashtm.example.com/squash/test-case-workspace/test-case/21/content"
      ),
      SquashTMIntegration::RequirementLoader::TestCase.new(
        id: 22, name: "Wrong password", reference: nil, description: nil, execution_status: nil,
        last_executed_on: nil, last_executed_by: nil,
        url: "https://squashtm.example.com/squash/test-case-workspace/test-case/22/content"
      )
    ]
  end
  let(:requirement) do
    SquashTMIntegration::RequirementLoader::Requirement.new(
      id: 11, name: "Users can sign in", reference: "REQ-001", status: "APPROVED", test_cases:
    )
  end

  current_user { build_stubbed(:user) }

  subject(:render_component) { render_inline(described_class.new(view_model, linked_requirement:)) }

  it "shows the requirement with a link to SquashTM" do
    render_component

    expect(page).to have_text("REQ-001")
    expect(page).to have_text("Approved")
    expect(page).to have_link("Users can sign in", href: %r{/requirement-workspace/requirement-library/11/content})
  end

  it "lists the test cases with their latest execution status" do
    render_component

    expect(page).to have_css("[data-test-selector='squashtm--test-case-21']", text: "Passed")
    expect(page).to have_css("[data-test-selector='squashtm--test-case-21']", text: "by bob")
    expect(page).to have_css("[data-test-selector='squashtm--test-case-22']", text: "Not executed")
  end

  it "offers no unlink action without the permission" do
    render_component

    expect(page).to have_no_css("[data-test-selector='squashtm--unlink-requirement']")
  end

  context "for a user allowed to manage links" do
    let(:can_manage_links) { true }

    it "offers to unlink the requirement" do
      render_component

      expect(page).to have_css("[data-test-selector='squashtm--unlink-requirement']")
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
    let(:error) { :not_found }

    it "warns and keeps showing the cached name" do
      render_component

      expect(page).to have_css("[data-test-selector='squashtm--requirement-missing']")
      expect(page).to have_text("Users can sign in")
    end
  end

  context "when SquashTM is not reachable" do
    let(:requirement) { nil }
    let(:error) { :unavailable }

    it "explains that the test cases could not be loaded" do
      render_component

      expect(page).to have_css("[data-test-selector='squashtm--test-cases-unavailable']")
      expect(page).to have_text("Users can sign in")
    end
  end

  it "renders inside its own turbo frame" do
    render_component

    expect(page).to have_css("turbo-frame##{described_class::TURBO_FRAME_ID}")
  end
end
