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

require "rails_helper"

RSpec.describe SquashTMIntegration::RequirementLoader do
  let(:client) { instance_double(SquashTMIntegration::Client) }

  subject(:loader) { described_class.new(client) }

  before { allow(client).to receive(:test_case_url) { "https://squashtm.example.com/test-case/#{it}" } }

  describe "#load_linked_requirement" do
    let(:requirement) do
      {
        "id" => 11,
        "name" => "Users can sign in",
        "current_version" => {
          "name" => "Users can sign in",
          "reference" => "REQ-001",
          "status" => "APPROVED",
          "verifying_test_cases" => [{ "id" => 21, "name" => "Valid login" }, { "id" => 22, "name" => "Wrong password" }]
        }
      }
    end
    let(:requirement_result) { result.requirement }

    before do
      allow(client).to receive(:requirement).with(11).and_return(requirement)
      allow(client).to receive(:test_case).with(21).and_return(
        { "id" => 21, "name" => "Valid login", "reference" => "TC-001", "description" => "<p>Signs in.</p>" }
      )
      allow(client).to receive(:test_case).with(22).and_return({ "id" => 22, "name" => "Wrong password", "description" => nil })
      allow(client).to receive(:test_case_executions).with(21).and_return(
        [
          { "execution_status" => "SUCCESS", "last_executed_on" => "2026-10-24T10:00:00.000Z", "last_executed_by" => "bob" },
          { "execution_status" => "FAILURE", "last_executed_on" => "2026-10-25T08:00:00.000Z", "last_executed_by" => "alice" },
          { "execution_status" => "READY", "last_executed_on" => nil, "last_executed_by" => nil }
        ]
      )
      allow(client).to receive(:test_case_executions).with(22).and_return(
        [{ "execution_status" => "READY", "last_executed_on" => nil, "last_executed_by" => nil }]
      )
    end

    subject(:result) { loader.load_linked_requirement(11) }

    context "when SquashTM returns the requirement" do
      it "returns the requirement with its verifying test cases" do
        expect(requirement_result).to have_attributes(id: 11, name: "Users can sign in", reference: "REQ-001", status: "APPROVED")
        expect(requirement_result.test_cases.map(&:id)).to eq([21, 22])
      end

      it "links each test case to SquashTM" do
        expect(requirement_result.test_cases.first.url).to eq("https://squashtm.example.com/test-case/21")
      end

      it "includes the reference and description of each test case" do
        expect(requirement_result.test_cases.first).to have_attributes(reference: "TC-001", description: "<p>Signs in.</p>")
        expect(requirement_result.test_cases.last).to have_attributes(reference: nil, description: nil)
      end

      it "uses the most recent execution across all iterations" do
        test_case = requirement_result.test_cases.first

        expect(test_case).to have_attributes(execution_status: "FAILURE", last_executed_by: "alice")
        expect(test_case.last_executed_on).to eq(Time.zone.parse("2026-10-25T08:00:00Z"))
      end

      it "treats a test case without a finished execution as not executed" do
        expect(requirement_result.test_cases.last).not_to be_executed
        expect(requirement_result.test_cases.last.execution_status).to be_nil
      end

      it "has no error" do
        expect(result.error).to be_nil
      end
    end

    it "reports :not_found when the requirement no longer exists" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::NotFoundError.new(404))

      expect(result).to have_attributes(requirement: nil, error: :not_found)
    end

    it "reports :unavailable when SquashTM cannot be reached" do
      allow(client).to receive(:requirement).and_raise(SquashTMIntegration::Client::TimeoutError)

      expect(result).to have_attributes(requirement: nil, error: :unavailable)
    end
  end

  describe "#load_project_requirements" do
    it "lists the requirements with their references" do
      allow(client).to receive(:all_requirements).with(3).and_return(
        [{ "id" => 2, "name" => "Sign in", "extra" => 1, "current_version" => { "reference" => "REQ-002" } }]
      )

      expect(loader.load_project_requirements(3)).to eq([{ id: 2, name: "Sign in", reference: "REQ-002" }])
    end

    it "sorts alphabetically by reference and then by name" do
      allow(client).to receive(:all_requirements).with(3).and_return(
        [{ "id" => 1, "name" => "b no reference", "current_version" => { "reference" => "" } },
         { "id" => 2, "name" => "Ten", "current_version" => { "reference" => "REQ-10" } },
         { "id" => 3, "name" => "a no reference" },
         { "id" => 4, "name" => "Two", "current_version" => { "reference" => "REQ-2" } },
         { "id" => 5, "name" => "One", "current_version" => { "reference" => "REQ-001" } }]
      )

      expect(loader.load_project_requirements(3).pluck(:id)).to eq([3, 1, 5, 2, 4])
    end

    it "is nil when SquashTM cannot be reached" do
      allow(client).to receive(:all_requirements).and_raise(SquashTMIntegration::Client::TimeoutError)

      expect(loader.load_project_requirements(3)).to be_nil
    end
  end
end
