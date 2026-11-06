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

RSpec.describe SquashTMIntegration::RequirementCoverage do
  let(:client) { instance_double(SquashTMIntegration::Client) }
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

  subject(:coverage) { described_class.new(client).call(11) }

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

  it "returns the requirement with its verifying test cases" do
    expect(coverage).to have_attributes(id: 11, name: "Users can sign in", reference: "REQ-001", status: "APPROVED")
    expect(coverage.test_cases.map(&:id)).to eq([21, 22])
  end

  it "includes the reference and description of each test case" do
    expect(coverage.test_cases.first).to have_attributes(reference: "TC-001", description: "<p>Signs in.</p>")
    expect(coverage.test_cases.last).to have_attributes(reference: nil, description: nil)
  end

  it "uses the most recent execution across all iterations" do
    test_case = coverage.test_cases.first

    expect(test_case).to have_attributes(execution_status: "FAILURE", last_executed_by: "alice")
    expect(test_case.last_executed_on).to eq(Time.zone.parse("2026-10-25T08:00:00Z"))
  end

  it "treats a test case without a finished execution as not executed" do
    expect(coverage.test_cases.last).not_to be_executed
    expect(coverage.test_cases.last.execution_status).to be_nil
  end
end
